const Service = require('node-windows').Service;
const path = require('path');

const svc = new Service({
   name: 'SmartPOS Printer Agent',
   description: 'Automatic printing service for Smart POS Web.',
   script: path.join(__dirname, 'index.js'),
   nodeOptions: ['--harmony'],
   workingDirectory: __dirname,
});

svc.on('install', function () {
   console.log('✅ Service installed successfully.');
   console.log('🚀 Starting service...');
   svc.start();
});

svc.on('alreadyinstalled', function () {
   console.log('⚠️ The service was already installed.');
   console.log('Attempting to start...');
   svc.start();
});

svc.on('start', function () {
   console.log('⚡ The service has started and is running in the background.');
});

svc.install();
