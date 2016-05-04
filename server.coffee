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
   saveSub: (doc, page, type) ->
      checkAdmin()
      if type is "text" or type is "textarea"
         content = doc.content.replace(/<br\s*[\/]?>/gi,'\n')
         set =
         "subs.#{doc.pdata}.#{doc.title}":
            content: content
            type: doc.type
         Pages.update {title: page}, {$set:set}
      else if type is "list"
         Pages.update 
            title: page
            "subs.#{doc.pdata}.#{doc.title}.content.order": Number doc.order
         ,
            $set: 
               "subs.#{doc.pdata}.#{doc.title}.content.$.content":
                  _.object _.map doc, (value, key) -> [key, value.replace(/<br\s*[\/]?>/gi,'\n')]
   addAgendaItem: (doc, page)->
      checkAdmin()
      p = Pages.findOne({title: page})
      highest = _.max p.subs[doc.pdata][doc.title].content, (o) -> o.order
      highest.order += 1
      Pages.update
         title: page
         {$push: "subs.#{doc.pdata}.#{doc.title}.content": 
            $each: [ 
               order: highest.order
               content:
                  datum: ""
                  locatie: ""
                  gemeente: ""
                  beschrijving: ""
                  uur: ""] }
   removeAgendaItem: (doc, page)->
      checkAdmin()
      Pages.update
         title: page
         { $pull: 
            "subs.#{doc.pdata}.#{doc.title}.content": 
               order: doc.order }
      
   changeOrder: (page, doc, dir, currentOrder) ->
      # Not in use
      checkAdmin()
      # Define collection first!
      col = Pages
      obj = col.findOne {title: page}
      
      if dir is 'down'
         # console.log 'DOWN'
         unless obj.order + 1 is col.find().fetch().length
            # console.log "subs.#{doc.pdata}.#{doc.title}.content.order"
            # console.log obj._id
            # console.log Number(currentOrder)+1
            col.update 
               title: page
               "subs.#{doc.pdata}.#{doc.title}.content.order": Number(currentOrder)+1
            ,  
               $set:
                  "subs.#{doc.pdata}.#{doc.title}.content.order": Number currentOrder
            col.update 
               _id: obj._id
               $set: 
                  "subs.#{doc.pdata}.#{doc.title}.content.order": Number(currentOrder)+1
      if dir is 'up'
         unless obj.order is 0
            col.update {order:currentOrder-1}, {$set:{order:currentOrder}}
            col.update {_id:obj._id}, {$set:{order:currentOrder-1}}