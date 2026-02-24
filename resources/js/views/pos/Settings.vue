<template>
    <PosLayout>
        <div class="h-full flex flex-col bg-gray-50 overflow-hidden">
            <!-- Page Header -->
            <div class="px-6 py-6 shrink-0 bg-white border-b border-gray-100">
                <h2 class="text-2xl font-bold text-gray-900">Settings</h2>
            </div>

            <!-- Main Content -->
            <main class="flex-1 overflow-y-auto p-6 pb-28 scroll-smooth">
                
                <!-- Tax & Service Charge Section -->
                <section class="mb-8">
                    <h3 class="text-sm font-bold uppercase tracking-wider text-gray-500 mb-3 px-1">Payment Settings</h3>
                    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden divide-y divide-gray-100">
                        
                        <!-- Tax Toggle -->
                        <div class="p-5 flex items-center justify-between gap-4">
                            <div class="flex flex-col">
                                <span class="font-bold text-slate-900 text-base">Tax (PPN)</span>
                                <span class="text-sm text-gray-500">Enable 10% tax calculation</span>
                            </div>
                            <label class="flex items-center cursor-pointer relative">
                                <input type="checkbox" v-model="settings.tax_enabled" @change="updateSettings" class="sr-only peer">
                                <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                            </label>
                        </div>

                        <!-- Service Charge Toggle -->
                        <div class="p-5 flex items-center justify-between gap-4">
                            <div class="flex flex-col">
                                <span class="font-bold text-slate-900 text-base">Service Charge</span>
                                <span class="text-sm text-gray-500">Enable 5% service charge</span>
                            </div>
                            <label class="flex items-center cursor-pointer relative">
                                <input type="checkbox" v-model="settings.service_charge_enabled" @change="updateSettings" class="sr-only peer">
                                <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                            </label>
                        </div>

                    </div>
                </section>

                <!-- Connected Device Section -->
                <section class="mb-8">
                    <h3 class="text-sm font-bold uppercase tracking-wider text-gray-500 mb-3 px-1">Connected Device</h3>
                    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                        <!-- Device Item -->
                        <div v-if="bluetooth.connectedDevice" class="p-4 flex items-center justify-between gap-4 border-b border-gray-100">
                            <div class="flex items-center gap-4">
                                <div class="w-12 h-12 rounded-lg bg-green-50 flex items-center justify-center text-green-600 shrink-0">
                                    <PrinterIcon class="w-6 h-6" />
                                </div>
                                <div>
                                    <p class="font-bold text-slate-900 text-base">{{ bluetooth.connectedDevice.name || 'Unknown Printer' }}</p>
                                    <div class="flex items-center gap-1.5 mt-0.5">
                                        <span class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
                                        <p class="text-sm font-medium text-green-600">Connected • Ready</p>
                                    </div>
                                </div>
                            </div>
                            <button @click="disconnectPrinter" class="text-gray-400 hover:text-red-500 transition-colors p-2" title="Disconnect">
                                <LogOutIcon class="w-5 h-5" />
                            </button>
                        </div>
                        <div v-else class="p-8 text-center text-gray-400 bg-gray-50">
                            <PrinterIcon class="w-12 h-12 mx-auto mb-2 text-gray-300" />
                            <p>No printer connected</p>
                        </div>

                        <!-- Quick Actions -->
                        <div v-if="bluetooth.connectedDevice" class="p-3 bg-gray-50/50 flex">
                            <button @click="testPrint" :disabled="bluetooth.printing" class="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-lg border border-primary text-primary hover:bg-primary/5 active:bg-primary/10 transition-all font-bold text-sm disabled:opacity-50 disabled:cursor-not-allowed">
                                <PrinterIcon class="w-4 h-4" />
                                {{ bluetooth.printing ? 'Printing...' : 'Test Print' }}
                            </button>
                        </div>
                    </div>
                </section>

                <!-- Printing Preferences (From HTML) -->
                <section class="mb-8">
                    <h3 class="text-sm font-bold uppercase tracking-wider text-gray-500 mb-3 px-1">Printing Preferences</h3>
                    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden divide-y divide-gray-100">
                        <!-- Auto-print Toggle -->
                        <div class="p-4 flex items-center justify-between gap-4">
                            <div class="flex flex-col">
                                <span class="font-semibold text-slate-900">Auto-print Receipt</span>
                                <span class="text-sm text-gray-500">Print automatically after payment</span>
                            </div>
                            <label class="flex items-center cursor-pointer relative">
                                <input type="checkbox" checked class="sr-only peer">
                                <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                            </label>
                        </div>
                        <!-- Paper Size -->
                        <div class="p-4">
                            <div class="flex items-center justify-between mb-3">
                                <span class="font-semibold text-slate-900">Paper Size</span>
                            </div>
                            <div class="flex gap-3 bg-gray-100 p-1 rounded-lg">
                                <button class="flex-1 py-2 px-3 rounded-md bg-white shadow-sm text-primary font-bold text-sm transition-all border border-gray-200">
                                    58mm
                                </button>
                                <button class="flex-1 py-2 px-3 rounded-md text-gray-500 font-medium text-sm hover:text-slate-900 transition-all">
                                    80mm
                                </button>
                            </div>
                        </div>
                    </div>
                </section>

                <!-- Available Devices (Web Bluetooth) -->
                <section class="mb-4">
                    <div class="flex items-center justify-between mb-3 px-1">
                        <h3 class="text-sm font-bold uppercase tracking-wider text-gray-500">Add New Device</h3>
                    </div>
                    
                    <button 
                        @click="startScan"
                        class="w-full bg-white hover:bg-gray-50 text-left p-4 rounded-xl shadow-sm border border-gray-100 flex items-center justify-between gap-4 transition-all group"
                    >
                        <div class="flex items-center gap-4">
                            <div class="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center text-blue-600 shrink-0 group-hover:scale-110 transition-all">
                                <BluetoothIcon class="w-5 h-5" />
                            </div>
                            <div class="flex flex-col">
                                <p class="font-semibold text-slate-900 text-base">Scan for Bluetooth Printers</p>
                                <p class="text-sm text-gray-500">Click to search available devices...</p>
                            </div>
                        </div>
                        <ChevronRightIcon class="w-5 h-5 text-gray-300 group-hover:text-primary" />
                    </button>
                    
                    <p class="mt-3 text-xs text-gray-400 px-1 text-center">
                        Note: Requires Chrome/Edge browser. Ensure your printer is powered on and not connected to another device.
                    </p>
                </section>

            </main>
        </div>
    </PosLayout>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue';
import PosLayout from '../../components/layout/PosLayout.vue';
import { 
    ChevronLeftIcon, PrinterIcon, SettingsIcon, 
    RefreshCwIcon, BluetoothIcon, ChevronRightIcon, LogOutIcon 
} from 'lucide-vue-next';
import api from '../../api/axios';
import { useToast } from 'vue-toastification';

const toast = useToast();
const loading = ref(false);

const settings = reactive({
    tax_enabled: false,
    service_charge_enabled: false
});

// Bluetooth State
const bluetooth = reactive({
    device: null,
    server: null,
    characteristic: null,
    connectedDevice: null,
    printing: false
});

// ESC/POS Commands
const ESC = '\x1B';
const GS = '\x1D';
const commands = {
    INIT: ESC + '@',
    CUT: GS + 'V' + '\x41' + '\x00',
    TEXT_BIG: ESC + '!' + '\x30',
    TEXT_NORMAL: ESC + '!' + '\x00',
    ALIGN_CENTER: ESC + 'a' + '\x01',
    ALIGN_LEFT: ESC + 'a' + '\x00',
    FEED_LINES: (n) => ESC + 'd' + String.fromCharCode(n)
};

    const fetchSettings = async () => {
    try {
        const response = await api.get('/settings');
        const data = response.data?.data || response.data || {};
        
        // Data is a key-value object (from pluck), not an array
        // Example: { tax_rate: "10", service_charge_rate: "5" }
        
        settings.tax_enabled = data.tax_rate ? parseFloat(data.tax_rate) > 0 : false;
        settings.service_charge_enabled = data.service_charge_rate ? parseFloat(data.service_charge_rate) > 0 : false;
    } catch (e) {
        console.error('Failed to load settings', e);
    }
};

const updateSettings = async () => {
    loading.value = true;
    try {
        const updates = [
            { key: 'tax_rate', value: settings.tax_enabled ? '10' : '0' },
            { key: 'service_charge_rate', value: settings.service_charge_enabled ? '5' : '0' }
        ];

        for (const update of updates) {
             await api.post('/admin/settings', update);
        }

        toast.success('Settings updated successfully');
        window.location.reload(); 
    } catch (e) {
        toast.error('Failed to update settings');
        console.error(e);
        await fetchSettings();
    } finally {
        loading.value = false;
    }
};

// Bluetooth Actions
const startScan = async () => {
    if (!navigator.bluetooth) {
        toast.error('Web Bluetooth is not supported in this browser. Please use Chrome or Edge.');
        return;
    }

    try {
        const device = await navigator.bluetooth.requestDevice({
            filters: [
                { services: ['000018f0-0000-1000-8000-00805f9b34fb'] }, // Standard Printer Service
            ],
            optionalServices: ['000018f0-0000-1000-8000-00805f9b34fb'], 
            acceptAllDevices: false 
        }).catch(err => {
            // Fallback: try accepting all devices if filter fails (some printers don't advertise service correctly)
            return navigator.bluetooth.requestDevice({
                 acceptAllDevices: true,
                 optionalServices: ['000018f0-0000-1000-8000-00805f9b34fb']
            });
        });

        if (device) {
            connectToPrinter(device);
        }
    } catch (e) {
        if (e.name !== 'NotFoundError') { // User cancelled
            console.error('Bluetooth Scan Error:', e);
            toast.error('Failed to connect: ' + e.message);
        }
    }
};

const connectToPrinter = async (device) => {
    try {
        const server = await device.gatt.connect();
        const service = await server.getPrimaryService('000018f0-0000-1000-8000-00805f9b34fb');
        const characteristic = await service.getCharacteristic('00002af1-0000-1000-8000-00805f9b34fb'); // Write Characteristic

        bluetooth.device = device;
        bluetooth.server = server;
        bluetooth.characteristic = characteristic;
        bluetooth.connectedDevice = {
            id: device.id,
            name: device.name
        };

        device.addEventListener('gattserverdisconnected', onDisconnected);
        
        toast.success(`Connected to ${device.name}`);
        
        // Save to local storage for persistence check (reconnect logic is complex due to user gesture requirement)
        localStorage.setItem('pos_printer_name', device.name);

    } catch (e) {
        console.error('Connection Error:', e);
        toast.error('Could not connect to printer. Ensure it supports BLE/Web Bluetooth.');
    }
};

const onDisconnected = () => {
    bluetooth.connectedDevice = null;
    bluetooth.device = null;
    bluetooth.server = null;
    bluetooth.characteristic = null;
    toast.info('Printer disconnected');
};

const disconnectPrinter = () => {
    if (bluetooth.device && bluetooth.device.gatt.connected) {
        bluetooth.device.gatt.disconnect();
    }
};

const testPrint = async () => {
    if (!bluetooth.characteristic) {
        toast.error('Printer not connected');
        return;
    }

    bluetooth.printing = true;
    try {
        const encoder = new TextEncoder();
        const data = [
            commands.INIT,
            commands.ALIGN_CENTER,
            commands.TEXT_BIG,
            'TEST PRINT\n',
            commands.TEXT_NORMAL,
            '--------------------------------\n',
            commands.ALIGN_LEFT,
            'Printer: ' + bluetooth.connectedDevice.name + '\n',
            'Connection: Bluetooth LE\n',
            'Status: Success\n',
            '--------------------------------\n',
            commands.FEED_LINES(3),
            commands.CUT
        ].join('');

        // Web Bluetooth write value limits (usually 512 bytes). Chunking might be needed for large prints.
        await bluetooth.characteristic.writeValue(encoder.encode(data));
        toast.success('Test print sent!');
    } catch (e) {
        console.error('Print Error:', e);
        toast.error('Failed to print: ' + e.message);
    } finally {
        bluetooth.printing = false;
    }
};

onMounted(() => {
    fetchSettings();
    
    // Check if we had a printer connected previously (just visual indicator, user still needs to reconnect manually due to browser security)
    const savedPrinter = localStorage.getItem('pos_printer_name');
    if (savedPrinter) {
        // We can't auto-reconnect without user gesture usually, but we could prompt
        // For now, we leave it clean to avoid confusion
    }
});
</script>
