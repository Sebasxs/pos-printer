const Service = require('node-windows').Service;
const path = require('path');

const svc = new Service({
   name: 'SmartPOS Printer Agent',
   script: path.join(__dirname, 'index.js'),
});

svc.on('uninstall', function () {
   console.log('Service uninstalled.');
});

svc.uninstall();
