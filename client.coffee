Meteor.subscribe 'pages', {}

Template.registerHelper 'page', (args) ->
   #args.hash has page, sub(=optional), content and type
   a = args.hash
   page = Pages.findOne {title:a.page}
   unless page?.subs[a.sub]?[a.content]?.content
      Meteor.call 'addPage', a
   return page?.subs[a.sub]?[a.content]?.content

Template.registerHelper 'admin', -> return true if Roles.userIsInRole Meteor.userId(), 'admin'

Template.adminLayout.helpers
   pages: -> Pages.find {}

Router.route '/admin',
   name: 'admin'
   layoutTemplate: 'adminLayout'
   waitOn: -> Meteor.subscribe 'pages', {}
   data: -> Pages.find {}

Router.route '/admin/:page?',
   name: 'page'
   layoutTemplate: 'adminLayout'
   waitOn: -> Meteor.subscribe 'pages', {}
   data: -> 
      page = Pages.findOne {title:this.params.page}
      pagesubs = []
      _.each page?.subs, (sub, key) ->
         pagesub =
            title: key
            comps: []
         _.each sub, (c,k) ->
            c.title = k
            c.content = c.content.replace(/<br>/g, '\n')
            c.pdata = key
            pagesub.comps.push c
         pagesubs.push pagesub
      data =
         subs: pagesubs
         title: page?.title
      return data

Template.component.helpers
   type: (type) -> return true if type is this.type

Template.component.events
   'click .saveSub': (e,t) ->
      doc = this
      doc.content = $("##{this.title}").val()
      doc.content = doc.content.replace(/\n/g,'<br>')
      page = Router.current().params.sub
      Meteor.call 'saveSub', doc, page
      $(e.currentTarget).html('Saved...')
      Meteor.setTimeout ->
         $(e.currentTarget).html('Save')
      , 2000
