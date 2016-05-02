Meteor.publish 'pages', (q) ->
   Pages.find q

Meteor.startup ->
   unless Meteor.users.findOne()
      id = Accounts.createUser
         email: 'admin@test.be'
         password: 'test'
         profile:
            name: 'admin'
      Roles.addUsersToRoles id, ['admin']

checkAdmin = ->
   unless Roles.userIsInRole Meteor.userId(), 'admin'
      throw new Meteor.Error 401, 'Access denied'

Meteor.methods
   addPage: (args) ->
      #args has page, sub, content and type
      page = Pages.findOne {title:args.page}
      if page
         update =
            $set: {}
         if page.subs[args.sub]
            if page.subs[args.sub][args.content]
               return
         update.$set['subs.'+args.sub+'.'+args.content] =
            content: "Insert text here"
            type: args.type
         console.log update
         Pages.update {_id:page._id}, update
      else
         subs = {}
         subs[args.sub] = {}
         subs[args.sub][args.content] =
            content: "Insert text here"
            type: args.type
         Pages.insert
            title: args.page
            subs: subs
   saveSub: (doc, page) ->
      checkAdmin()
      content = doc.content.replace(/<br\s*[\/]?>/gi,'\n')
      set =
         "subs.#{doc.pdata}.#{doc.title}":
            content: content
            type: doc.type
      Pages.update {title: page}, {$set:set}
   changeOrder: (collection, dir, currentOrder) ->
      # Not in use
      checkAdmin()
      # Define collection first!
      # col = ...
      obj = col.findOne {order:currentOrder}
      if dir is 'down'
         unless obj.order + 1 is col.find().fetch().length
            col.update {order:currentOrder+1}, {$set:{order:currentOrder}}
            col.update {_id:obj._id}, {$set:{order:currentOrder+1}}
      if dir is 'up'
         unless obj.order is 0
            col.update {order:currentOrder-1}, {$set:{order:currentOrder}}
            col.update {_id:obj._id}, {$set:{order:currentOrder-1}}