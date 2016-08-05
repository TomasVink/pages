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
   addListItem: (doc, page)->
      checkAdmin()
      p = Pages.findOne({title: page})
      highest = _.max p.subs[doc.pdata][doc.title].content, (o) -> o.order
      highest.order += 1
      Pages.update
         title: page
         {$push: "subs.#{doc.pdata}.#{doc.title}.content": 
            $each: [ 
               id: Random.id()
               order: highest.order or 0
               content:
                  item: ""] }
   addAgendaItem: (doc, page)->
      checkAdmin()
      p = Pages.findOne({title: page})
      highest = _.max p.subs[doc.pdata][doc.title].content, (o) -> o.order
      highest.order += 1
      Pages.update
         title: page
         {$push: "subs.#{doc.pdata}.#{doc.title}.content": 
            $each: [ 
               id: Random.id()
               order: highest.order or 0
               content:
                  datum: ""
                  locatie: ""
                  gemeente: ""
                  soort: ""
                  beschrijving: ""
                  uur: ""
                  extra: ""] }
   removeListItem: (doc, page)->
      checkAdmin()
      Pages.update
         title: page
         { $pull: 
            "subs.#{doc.pdata}.#{doc.title}.content": 
               order: doc.order }
      _.each Pages.findOne({title:page}).subs[doc.pdata][doc.title].content, (item) ->
         if item.order > doc.order
            Pages.update
               title: page
               "subs.#{doc.pdata}.#{doc.title}.content.id": item.id
            ,
               $set:
                  "subs.#{doc.pdata}.#{doc.title}.content.$.order": item.order-1
      
   changeOrder: (page, doc, dir, currentOrder) ->
      # Not in use
      checkAdmin()
      # Define collection first!
      col = Pages
      page = col.findOne {title: page}
      obj = _.find page.subs[doc.pdata][doc.title].content, (item) -> item.order is Number currentOrder
      
      if dir is 'down'
         unless Number(currentOrder)+1 is page.subs[doc.pdata][doc.title].content.length

            col.update 
               _id: page._id
               "subs.#{doc.pdata}.#{doc.title}.content.order": Number(currentOrder)+1
            ,  
               $set:
                  "subs.#{doc.pdata}.#{doc.title}.content.$.order": Number currentOrder
            col.update 
               _id: page._id
               "subs.#{doc.pdata}.#{doc.title}.content.id": obj.id
            ,
               $set: 
                  "subs.#{doc.pdata}.#{doc.title}.content.$.order": Number(currentOrder)+1
      if dir is 'up'
         unless Number(currentOrder) is 0
            col.update 
               _id: page._id
               "subs.#{doc.pdata}.#{doc.title}.content.order": Number(currentOrder)-1
            ,  
               $set:
                  "subs.#{doc.pdata}.#{doc.title}.content.$.order": Number currentOrder
            col.update 
               _id: page._id
               "subs.#{doc.pdata}.#{doc.title}.content.id": obj.id
            ,
               $set: 
                  "subs.#{doc.pdata}.#{doc.title}.content.$.order": Number(currentOrder)-1