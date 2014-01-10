class CollaborativeWorkspace extends Workspace

  init: ->
    {createUserList, enableChat} = @getOptions()
    @nickname    = KD.nick()
    @sessionData = []
    @users       = {}
    @createRemoteInstance()
    @createLoader()
    @fetchUsers()
    @createUserListContainer()  if createUserList
    @createChat()               if enableChat
    @bindRemoteEvents()

  createChat: ->
    chatPaneClass = @getOptions().chatPaneClass or ChatPane
    @container.addSubView @chatView = new chatPaneClass
      delegate  : this
      itemClass : TeamworkChatItem

    @chatView.hide()

  createRemoteInstance: ->
    instanceName  = @getOptions().firebaseInstance

    unless instanceName
      return warn "CollaborativeWorkspace requires a Firebase instance."

    @firebaseRef    = new Firebase "https://#{instanceName}.firebaseio.com/"
    @sessionKey     = @getOptions().sessionKey or @createSessionKey()
    @workspaceRef   = @firebaseRef.child @sessionKey
    @broadcastRef   = @workspaceRef.child "broadcast"
    @historyRef     = @workspaceRef.child "history"
    @chatRef        = @workspaceRef.child "chat"
    @watchRef       = @workspaceRef.child "watch"
    @usersRef       = @workspaceRef.child "users"
    @userRef        = @usersRef.child KD.nick()
    @sessionKeysRef = @firebaseRef.child  "session_keys"

  bindRemoteEvents: ->
    @workspaceRef.once "value", (snapshot) =>
      if @getOptions().sessionKey
        unless snapshot.val()?.keys
          @showNotActiveView()
          return false

      cb = =>
        isOldSession = keys = snapshot.val()?.keys
        if isOldSession
          @isOldSession = yes
          @sessionData  = keys
          @createPanel()
        else
          @createPanel()
          @workspaceRef.set "keys": @sessionData

        @setPresenceHandlers()

        record = if isOldSession then "$0 joined the session" else "$0 started the session"
        @addToHistory { message: record, by: KD.nick() }
        @watchRef.child(@nickname).set "everybody"
        @sessionKeysRef.child(@nickname).set @sessionKey
        @userRef.child("status").set "online"

        @loader.destroy()
        @chatView?.show()

        @emit "WorkspaceSyncedWithRemote"
        @emit "SomeoneJoinedToSession", KD.nick() if isOldSession

      if @amIHost() then cb()
      else
        @pingHost (status) =>
          cb()  if status is "online"

    @usersRef.on "child_added", (snapshot) =>
      @fetchUsers()

    @usersRef.on "child_changed", (snapshot) =>
      name = snapshot.name()
      if @amIHost() and snapshot.val()?.status is "offline"
        message = "#{name} has left the session"

        @broadcastMessage
          title     : message
          cssClass  : "error"
          sender    : name

        @addToHistory { message, by: KD.nick() }
        @emit "SomeoneHasLeftSession", name

    @broadcastRef.on "value", (snapshot) =>
      message = snapshot.val()
      return if not message or not message.data or message.data.sender is @nickname
      @displayBroadcastMessage message.data

    @on "AllPanesAddedToPanel", (panel, panes) ->
      paneSessionKeys = []
      paneSessionKeys.push pane.sessionKey for pane in panes
      @sessionData.push paneSessionKeys

    @on "KDObjectWillBeDestroyed", =>
      @forceDisconnect()
      events = [ "value", "child_added", "child_removed", "child_changed" ]
      @workspaceRef.off eventName for eventName in events

    @watchRef.on "value", (snapshot) =>
      @watchMap = snapshot.val() or {}

    @userRef.child("status").onDisconnect().set "offline"

  fetchUsers: ->
    @workspaceRef.once "value", (snapshot) =>
      val = snapshot.val()
      return  unless val

      usernames = []
      usernames.push username for own username, status of val.users unless @users[username]

      # TODO: Each time we are fetching user data that we already have. Needs to be fixed.
      KD.remote.api.JAccount.some { "profile.nickname": { "$in": usernames } }, {}, (err, jAccounts) =>
        @users[user.profile.nickname] = user for user in jAccounts
        @emit "WorkspaceUsersFetched"

  createPanel: (callback = noop) ->
    panelOptions             = @getOptions().panels[@lastCreatedPanelIndex]
    panelOptions.delegate    = @
    panelOptions.sessionKeys = @sessionData[@lastCreatedPanelIndex]  if @sessionData
    panelClass               = @getOptions().panelClass or CollaborativePanel
    newPanel                 = new panelClass panelOptions

    @container.addSubView newPanel
    @panels.push newPanel
    @activePanel = newPanel

    callback()
    @emit "PanelCreated", newPanel

  createSessionKey: ->
    u = KD.utils
    return "#{@nickname}_#{u.generatePassword(4)}_#{u.getRandomNumber(100)}"

  getHost: ->
    return @sessionKey.split("_").first

  amIHost: ->
    [sessionOwner] = @sessionKey.split "_"
    return sessionOwner is @nickname

  showNotActiveView: do ->
    notValid = null

    ->
      return  if notValid

      notValid = new KDView
        cssClass : "not-valid"
        partial  : "This session is not valid or no longer available."

      notValid.addSubView new KDView
        cssClass : "description"
        partial  : "This usually means, the person who is hosting this session is disconnected or closed the session."

      notValid.addSubView new KDButtonView
        cssClass : "tw-rounded-button new-session"
        title    : "Start new session"
        callback : =>
          @startNewSession()
          notValid.destroy()
          notValid = null

      @container.destroySubViews()
      @container.addSubView notValid
      @sessionNotActive = yes
      @loader.hide()

  startNewSession: ->
    @destroy()
    options = @getOptions()
    delete options.sessionKey
    @addSubView new CollaborativeWorkspace options

  createLoader: ->
    @loader    = new KDView
      cssClass : "workspace-loader"
      partial  : """<span class="text">Loading...<span>"""

    @loader.addSubView loaderView = new KDLoaderView size: width : 36
    @loader.on "viewAppended", -> loaderView.show()
    @container.addSubView @loader

  isJoinedASession: ->
    return @getHost() isnt KD.nick()

  joinSession: (newOptions) ->
    options                = @getOptions()
    options.sessionKey     = newOptions.sessionKey.trim()
    options.joinedASession = yes
    @destroy()

    @addSubView new CollaborativeWorkspace options

  forceDisconnect: ->
    return  unless @amIHost()
    @forcedToDisconnect = yes
    @workspaceRef.remove()
    KD.utils.wait 2000, => # check for user is still connected
      @forcedToDisconnect = no

  showJoinModal: ->
    options        = @getOptions()
    modal          = new KDModalView
      title        : options.joinModalTitle   or "Join New Session"
      content      : options.joinModalContent or "<p>This is your session key, you can share this key with your friends to work together.</p>"
      overlay      : yes
      cssClass     : "workspace-modal join-modal"
      width        : 600
      buttons      :
        Join       :
          title    : "Join Session"
          cssClass : "modal-clean-green"
          callback : => @handleJoinASessionFromModal sessionKeyInput.getValue(), modal
        Close      :
          title    : "Close"
          cssClass : "modal-cancel"
          callback : -> modal.destroy()

    modal.addSubView sessionKeyInput = new KDHitEnterInputView
      type         : "text"
      placeholder  : "Paste new session key and hit enter to join"
      callback     : => @handleJoinASessionFromModal sessionKeyInput.getValue(), modal

  handleJoinASessionFromModal: (sessionKey, modal) ->
    return unless sessionKey
    @joinSession { sessionKey }
    modal.destroy()

  createUserListContainer: ->
    @container.addSubView @userListContainer = new KDView
      cssClass : "user-list"

    @userListContainer.bindTransitionEnd()

  showUsers: ->
    return  if @userList
    @userListContainer.setClass "active"

    @createUserList()
    @userListContainer.addSubView @userList

  createUserList: ->
    @userList = new CollaborativeWorkspaceUserList {
      @workspaceRef
      @sessionKey
      container : @userListContainer
      delegate  : this
    }

  addToHistory: (data) ->
    target       = @historyRef.child Date.now()
    data         = message: data  if typeof data is "string"
    data.message = data.message.replace "$0", KD.nick()

    target.set data
    @emit "NewHistoryItemAdded", data

  broadcastMessage: (details) ->
    @broadcastRef.set
      data       :
        title    : details.title    or ""
        cssClass : details.cssClass  ? "success"
        duration : details.duration or 4200
        origin   : details.origin   or "users"
        sender   : details.sender    ? @nickname

    @broadcastRef.set {}

  displayBroadcastMessage: (options) ->
    # simple broadcast message is
    # { !title, duration=, origin=, sender=, cssClass= }

    return unless options.title

    options.title     = options.title.replace "$0", KD.nick()
    activePanel       = @getActivePanel()
    options.container = @getActivePanel()
    options.type      = "mini"
    options.cssClass  = KD.utils.curry "tw-broadcast", options.cssClass

    new KDNotificationView options

  setPresenceHandlers: ->
    @userRef = @usersRef.child @nickname

    @timestampInterval = @utils.repeat 1000, =>
      @userRef.child("timestamp").set new Date().getTime(), (err) =>
        return  unless err
        @utils.killRepeat interval

    @pingHostInterval = @utils.repeat 2000, @bound "pingHost"  unless @amIHost()

    @once "KDObjectWillBeDestroyed", =>
      @killConnectionTimers()

  checkHost: (snapshot, callback) ->
    unless host = snapshot.val()
      @showNotActiveView()
      @killConnectionTimers()
      return

    diff = new Date().getTime() - host.timestamp

    if diff <= 5000
      @hideNotification()
      @hostStatus = "online"
    else if diff >= 20000
      @hideNotification()
      @showNotActiveView()
      @hostStatus = "offline"
    else if diff >= 5000
      @showNotification "Host is experiencing connectivity issues"
      @hostStatus = "unknown"

    callback? @hostStatus

  pingHost: (callback) ->
    @usersRef.child(@getHost()).once "value", (snapshot) =>
      @checkHost snapshot, callback

  killConnectionTimers: ->
    @utils.killRepeat @timestampInterval
    @utils.killRepeat @pingHostInterval

  showNotification: (message) ->
    @hideNotification()
    @notification = new KDNotificationView
      title       : message
      duration    : 20000
      container   : this
      cssClass    : "error"
      type        : "mini"
      overlay     : {}

  hideNotification: ->
    @notification?.destroy()
