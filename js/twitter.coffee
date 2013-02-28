###
TwitterUser
Ryhan Hassan | ryhanh@me.com

Identifies a user's top friends.
###

class @TwitterUser

  constructor: (username) ->
    @username = username.toLowerCase()
    @friends

  # get_friends: -> @_fetchData @_handleData

  # Add a given weight to a friend
  add_Weight: (friend, weight) ->
    unless friend?
      return 0
    
    friend = friend.toLowerCase()
    if not @friends?
      @friends = { }
    if @friends[friend]?
      @friends[friend] += weight
    else
      @friends[friend] = weight

  # Return list of friends with weights
  get_friends: (cb) ->
    if @friends?
      return cb(@friends)

    api = "http://search.twitter.com/search.json?"
    params ="include_entities=true&count=100&rpp=99&q=#{@username}&callback=?"
    context = this
    $.getJSON(api + params, (data) => cb(@_handleFriends(data, context)))

  # Interpret API data. Add appropriate friend weights for each person.
  _handleFriends: (d, context) ->
    for tweet in d.results
      if tweet.from_user.toLowerCase() == context.username
        context.add_Weight(tweet.to_user, 10)
      else
        context.add_Weight(tweet.from_user, 3)
        context.add_Weight(tweet.to_user, 1)
    return context.friends

  get_conversations: (cb) ->
    users = @friends
    ###
    sorted = _.last(_.sortBy(_.pairs users, (x) -> x[1]), 19)
    names = _.map(sorted, (x) -> x[0])
    ###
    names = [ ]
    set = _.sortBy(_.pairs(users), (x) -> x[1] * -1)
    for user in set
      if user[1] > 2
        names.push(user[0])

    # names = _.keys(users)

    query = encodeURIComponent(names.join(" OR "))
    api = "http://search.twitter.com/search.json?"
    params ="include_entities=true&count=100&rpp=99&q=#{query}&callback=?"
    context = this
    $.getJSON(api + params, (data) => cb(@_handleRelated(data, context)))

  _handleRelated: (d, context) ->
    console.log({result: d.results})
    important = [ ]

    if not d.results?
      return important

    knows = (name) ->
      unless (name?)
        return false
      name = name.toLowerCase()
      return context.friends[name]?

    not_me = (name) ->
      unless (name?)
        return false
      name = name.toLowerCase()
      return (name != context.username)

    for tweet in d.results
      if tweet.iso_language_code == "en" # and tweet.in_reply_to_status_id?
        if not_me(tweet.from_user) and (tweet.to_user?)
          if knows(tweet.from_user) #or knows(tweet.to_user)
            important.push(tweet)

    return important

