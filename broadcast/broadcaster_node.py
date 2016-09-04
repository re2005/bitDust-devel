

"""
.. module:: broadcaster_node
.. role:: red

BitDust broadcaster_node() Automat

EVENTS:
    * :red:`broadcast-message-received`
    * :red:`broadcaster-connected`
    * :red:`broadcaster-disconnected`
    * :red:`init`
    * :red:`lookup-failed`
    * :red:`new-broadcaster-connected`
    * :red:`new-outbound-message`
    * :red:`reconnect`
    * :red:`shutdown`
    * :red:`timer-1min`
"""

#------------------------------------------------------------------------------ 

_Debug = True
_DebugLevel = 6

#------------------------------------------------------------------------------ 

import time
import json

#------------------------------------------------------------------------------ 

from logs import lg

from automats import automat

from main import config

from p2p import contact_status
from p2p import commands

from transport import callback

from p2p import p2p_service

#------------------------------------------------------------------------------ 

_BroadcasterNode = None

#------------------------------------------------------------------------------ 

def A(event=None, arg=None):
    """
    Access method to interact with the state machine.
    """
    global _BroadcasterNode
    if event is None and arg is None:
        return _BroadcasterNode
    if _BroadcasterNode is None:
        # set automat name and starting state here
        _BroadcasterNode = BroadcasterNode('broadcaster_node', 'AT_STARTUP', _DebugLevel, _Debug)
    if event is not None:
        _BroadcasterNode.automat(event, arg)
    return _BroadcasterNode
    
#------------------------------------------------------------------------------ 

class BroadcasterNode(automat.Automat):
    """
    This class implements all the functionality of the ``broadcaster_node()`` state machine.
    """

    timers = {
        'timer-1min': (60, ['BROADCASTING']),
        }
    
    def init(self):
        self.max_broadcasters = 1 + int(round(float(config.conf().getInt(
            'services/broadcasting/max-broadcast-connections')) / 3.0))
        self.connected_broadcasters = []
        self.messages_sent = {}
        self.broadcasters_finder = None
        self.last_success_action_time = None
        self.listeners = {}
        self.incoming_broadcast_message_callback = None

    def A(self, event, arg):
        """
        The state machine code, generated using `visio2python <http://bitdust.io/visio2python/>`_ tool.
        """
        if self.state == 'AT_STARTUP':
            if event == 'init':
                self.state = 'BROADCASTERS?'
                self.doInit(arg)
                self.doStartBroadcastersLookup(arg)
        elif self.state == 'BROADCASTERS?':
            if event == 'shutdown':
                self.state = 'CLOSED'
                self.doEraseBroadcasters(arg)
                self.doDestroyMe(arg)
            elif event == 'broadcaster-connected' and not self.isMoreNeeded(arg):
                self.state = 'BROADCASTING'
                self.doAddBroadcaster(arg)
            elif event == 'lookup-failed' and not self.isAnyBroadcasters(arg):
                self.state = 'OFFLINE'
            elif event == 'lookup-failed' and self.isAnyBroadcasters(arg):
                self.doStartBroadcastersLookup(arg)
            elif event == 'broadcaster-connected' and self.isMoreNeeded(arg):
                self.doAddBroadcaster(arg)
                self.doStartBroadcastersLookup(arg)
        elif self.state == 'OFFLINE':
            if event == 'shutdown':
                self.state = 'CLOSED'
                self.doDestroyMe(arg)
            elif event == 'reconnect' or event == 'new-broadcaster-connected':
                self.state = 'BROADCASTERS?'
                self.doAddBroadcaster(arg)
                self.doStartBroadcastersLookup(arg)
        elif self.state == 'CLOSED':
            pass
        elif self.state == 'BROADCASTING':
            if event == 'shutdown':
                self.state = 'CLOSED'
                self.doEraseBroadcasters(arg)
                self.doDestroyMe(arg)
            elif event == 'new-broadcaster-connected':
                self.doAddBroadcaster(arg)
            elif event == 'broadcast-message-received':
                self.doCheckAndSendForward(arg)
            elif event == 'broadcaster-disconnected':
                self.doRemoveBroadcaster(arg)
            elif event == 'new-outbound-message':
                self.doBroadcastMessage(arg)
            elif event == 'timer-1min' and self.isLineActive(arg):
                self.doTestReconnectBroadcasters(arg)
            elif event == 'timer-1min' and not self.isLineActive(arg):
                self.state = 'OFFLINE'
                self.doEraseBroadcasters(arg)
        return None

    def isLineActive(self, arg):
        """
        Condition method.
        """
        for idurl in self.connected_broadcasters:
            if contact_status.isOnline(idurl):
                # if at least one broadcaster is connected
                # we assume the line is still active 
                return True
        if not self.last_success_action_time:
            return False
        return time.time() - self.last_success_action_time > 5*60

    def isAnyBroadcasters(self, arg):
        """
        Condition method.
        """
        return len(self.connected_broadcasters) > 0

    def isMoreNeeded(self, arg):
        """
        Condition method.
        """
        return len(self.connected_broadcasters) < self.max_broadcasters

    def doInit(self, arg):
        """
        Action method.
        """
        self.incoming_broadcast_message_callback = arg
        callback.append_inbox_callback(self._on_inbox_packet)

    def doStartBroadcastersLookup(self, arg):
        """
        Action method.
        """
        from broadcast import broadcasters_finder
        broadcasters_finder.A('start', 
            (self.automat, 'route', self.connected_broadcasters))
        
    def doAddBroadcaster(self, arg):
        """
        Action method.
        """
        if not arg:
            return
        if arg in self.connected_broadcasters:
            lg.warn('%s already connected as broadcaster' % arg)
            return
        if arg in self.listeners:
            lg.warn('%s already connected as listener' % arg)
        self.connected_broadcasters.append(arg)
        self.last_success_action_time = time.time()
        if _Debug:
            lg.out(_DebugLevel, 'broadcaster_node.doAddBroadcaster %s !!!!!!!!' % arg)

    def doRemoveBroadcaster(self, arg):
        """
        Action method.
        """
        if arg not in self.connected_broadcasters:
            lg.warn('%s is not connected' % arg)
            return
        self.connected_broadcasters.remove(arg)

    def doEraseBroadcasters(self, arg):
        """
        Action method.
        """
        self.connected_broadcasters = []

    def doCheckAndSendForward(self, arg):
        """
        Action method.
        """
        try:
            msg = json.loads(arg.Payload)
        except:
            lg.exc()
            return False
        self.last_success_action_time = time.time()
        msgid = msg['id']
        # skip broadcasting if this message was already sent
        if msgid in self.messages_sent:
            if _Debug:
                lg.out(_DebugLevel,
                    'broadcaster_node.doCheckAndSendForward resent skipped, %s was already sent to my broadcasters' % msgid)
            return
        # if some listeners connected - send to them
        for listener_idurl, scope in self.listeners.items():
            # but check if they really need that message
            # listener can set a scope, so he will get this broadcasting
            # only if creator of that message is listed in scope 
            if not scope or msg['creator'] in scope:
                p2p_service.SendBroadcastMessage(listener_idurl, msg)
        # fire broadcast listening callback
        if self.incoming_broadcast_message_callback is not None:
            self.incoming_broadcast_message_callback(msg)
        # finally broadcast further
        for idurl in self.connected_broadcasters:
            p2p_service.SendBroadcastMessage(idurl, msg)

    def doBroadcastMessage(self, arg):
        """
        Action method.
        """
        try:
            msg = json.loads(arg.Payload)
        except:
            lg.exc()
            return False
        msgid = msg['id']
        assert msgid in self.messages_sent
        self.messages_sent[msgid] = int(time.time())
        for idurl in self.connected_broadcasters:
            p2p_service.SendBroadcastMessage(idurl, msg)

    def doTestReconnectBroadcasters(self, arg):
        """
        Action method.
        """

    def doDestroyMe(self, arg):
        """
        Remove all references to the state machine object to destroy it.
        """
        self.incoming_broadcast_message_callback = None
        callback.remove_inbox_callback(self._on_inbox_packet)
        automat.objects().pop(self.index)
        global _BroadcasterNode
        del _BroadcasterNode
        _BroadcasterNode = None
    
    #------------------------------------------------------------------------------ 
    
    def add_listener(self, listener_idurl, scope):
        if listener_idurl in self.connected_broadcasters:
            lg.warn('%s already connected as broadcaster, can not set it as listener' % listener_idurl)
            return
        self.listeners[listener_idurl] = scope
        
    def remove_listener(self, listener_idurl):
        if listener_idurl not in self.listeners:
            lg.warn('%s not in listeners at the moment')
            return
        self.listeners.pop(listener_idurl)
    
    #------------------------------------------------------------------------------ 

    def _on_inbox_packet(self, newpacket, info, status, error_message):
        if status != 'finished':
            return False
        if newpacket.Command == commands.Broadcast():
            if newpacket.OwnerID in self.listeners:
                self.automat('new-outbound-message', newpacket)
            else:
                self.automat('broadcast-message-received', newpacket)
            return True
        return False