Package.describe({
   name: 'tomasvink:cms',
   summary: 'Basic cms for maintaining webpages',
   version: '0.1.0'
});

Package.onUse(function(api) {
   api.use(['mongo',
            'underscore',
            'blaze-html-templates',
            'templating',
            'coffeescript',
            'iron:router',
            'mquandalle:jade',
            'accounts-base',
            'accounts-password',
            'accounts-ui',
            'alanning:roles',
            'lepozepo:s3',
            'markdown',
            'check']);
   api.addFiles(['lib.coffee']);
   api.addFiles([
                  'admin.jade',
                  'client.coffee'
               ],'client');
   api.addFiles([
                  'server.coffee'
               ],'server');
   api.export('Pages',['client','server']);
});