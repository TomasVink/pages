Meteor.subscribe 'pages', {}

Template.registerHelper 'page', (args) ->
   #args.hash has page, sub(=optional), content and type
   a = args.hash
   console.log a
   page = Pages.findOne {title:a.page}
   unless page?.subs[a.sub]?[a.content]?.content
      Meteor.call 'addPage', a
   return page?.subs[a.sub]?[a.content]?.content

Template.registerHelper 'admin', -> Roles.userIsInRole Meteor.userId(), ['admin']

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
            if _.isArray c.content
               for item in c.content  
                  item.pdata = key
            c.pdata = key
            pagesub.comps.push c
         pagesubs.push pagesub
      data =
         subs: pagesubs
         title: page?.title
      return data

Template.component.helpers
   type: (type) -> return true if type is this.type

Template.list.helpers
   list: (agenda)->
      results = []
      for item in agenda
         results.push item
      return _.sortBy results, 'order'  
   
Template.component.events
   'click .saveSub': (e,t) ->
      doc = this
      sub = $(e.currentTarget).attr('sub')
      type = $(e.currentTarget).attr('type')
      title = $(e.currentTarget).attr('title')
      order = $(e.currentTarget).attr('order')
      
      if type is "text" or type is "textarea"
         doc.content = $("##{sub}-#{this.title}").val()
      else if type is "list"
         doc =
            datum: $("##{sub}-#{title}-datum-#{order}").val()
            locatie: $("##{sub}-#{title}-locatie-#{order}").val()
            gemeente: $("##{sub}-#{title}-gemeente-#{order}").val()
            beschrijving: $("##{sub}-#{title}-beschrijving-#{order}").val()
            uur: $("##{sub}-#{title}-uur-#{order}").val()
            order: order
            pdata: sub
            title: "#{title}"
      # console.log doc.pdata
      page = Router.current().params.page
      Meteor.call 'saveSub', doc, page, type
      $(e.currentTarget).html('Saved...')
      Meteor.setTimeout ->
         $(e.currentTarget).html('Save')
      , 2000
   'click .btn-add': (e,t) -> 
      page = Router.current().params.page
      # order = Number $(e.currentTarget).attr('order')
      # order += 1
      doc =
         pdata: $(e.currentTarget).attr('sub')
         # order: order
         type: $(e.currentTarget).attr('type')
         title: $(e.currentTarget).attr('title')
      Meteor.call 'addAgendaItem', doc, page 
   'click .btn-remove': (e,t) ->
      page = Router.current().params.page
      doc = 
         pdata: $(e.currentTarget).attr('sub')
         order: Number $(e.currentTarget).attr('order')
         title: $(e.currentTarget).attr('title')
      console.log doc
      Meteor.call 'removeAgendaItem', doc, page
   'click .btn-changeOrder': (e, t) ->
      dir = $(e.currentTarget).attr('dir')
      page = Router.current().params.page
      currentOrder = $(e.currentTarget).attr('order')
      doc = 
         pdata: $(e.currentTarget).attr('sub')
         title: $(e.currentTarget).attr('title')
      Meteor.call 'changeOrder', page, doc, dir, currentOrder 

