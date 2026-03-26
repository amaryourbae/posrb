<template>
    <Teleport to="body">
        <Transition name="fade">
            <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center">
                <div class="absolute inset-0 bg-black/50" @click="$emit('close')"></div>
                
                <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg mx-4 overflow-hidden">
                    <div class="p-6 border-b border-gray-100 flex justify-between items-center">
                        <h2 class="text-xl font-bold text-gray-900">Pending Bills</h2>
                        <button @click="$emit('close')" class="p-1 hover:bg-gray-100 rounded-full">
                            <XIcon class="w-5 h-5 text-gray-400" />
                        </button>
                    </div>
                    
                    <div class="p-6 max-h-96 overflow-y-auto">
                        <div v-if="loading" class="text-center py-8 text-gray-400">
                            <LoaderIcon class="w-6 h-6 animate-spin mx-auto mb-2" />
                            Loading bills...
                        </div>
                        
                        <div v-else-if="pendingBills.length === 0" class="text-center py-8 text-gray-400">
                            <ReceiptIcon class="w-12 h-12 mx-auto mb-3 opacity-50" />
                            <p>No pending bills found</p>
                        </div>
                        
                        <div v-else class="space-y-3">
                            <div 
                                v-for="bill in pendingBills" 
                                :key="bill.id"
                                class="p-4 bg-gray-50 rounded-xl border border-gray-100 hover:border-primary/50 cursor-pointer transition group"
                            >
                                <div class="flex flex-col sm:flex-row justify-between items-start gap-2 mb-2">
                                    <div class="flex-1 min-w-0 max-w-full">
                                        <div class="flex items-center flex-wrap gap-2">
                                            <h4 class="font-bold text-gray-900 text-sm sm:text-base break-all">{{ bill.order_number }}</h4>
                                            <span 
                                                class="text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wider"
                                                :class="bill.payment_status === 'paid' ? 'bg-green-100 text-green-700' : 'bg-orange-100 text-orange-700'"
                                            >
                                                {{ bill.payment_status === 'paid' ? 'Paid / App' : 'Pending' }}
                                            </span>
                                            <span 
                                                v-if="bill.order_type"
                                                class="text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wider bg-blue-100 text-blue-700"
                                            >
                                                {{ bill.order_type.replace('_app', '').replace('_', ' ') }}
                                            </span>
                                        </div>
                                        <p class="text-xs sm:text-sm text-gray-500 mt-1">{{ bill.customer_name || 'Walk-in' }}</p>
                                    </div>
                                    <span class="text-base sm:text-lg font-bold text-primary">{{ formatCurrency(bill.grand_total) }}</span>
                                </div>
                                <div class="flex items-center justify-between text-xs text-gray-400">
                                    <span>{{ bill.items?.length || 0 }} items</span>
                                    <span>{{ formatTime(bill.created_at) }}</span>
                                </div>

                                <!-- Order Items Summary -->
                                <div class="mt-3 mb-3 border-t border-dashed border-gray-200 pt-3 text-sm text-gray-800 space-y-2">
                                    <div v-for="item in bill.items" :key="item.id" class="flex justify-between items-start">
                                        <div class="flex-1">
                                            <p class="font-medium leading-tight">
                                                <span class="font-bold text-gray-900">{{ item.quantity }}x</span> {{ item.product_name }}
                                            </p>
                                            <!-- Modifiers -->
                                            <div v-if="getVisibleModifiers(item) && getVisibleModifiers(item).length" class="text-xs text-gray-500 mt-0.5 ml-5">
                                                <p v-for="(mod, idx) in getVisibleModifiers(item)" :key="idx">
                                                    + {{ mod.option_name || mod.name }}
                                                </p>
                                            </div>
                                        </div>
                                    </div>
                                    <!-- Order Note (Filtered) -->
                                    <div v-if="bill.note && !['pickup', 'pickup_app', 'dine_in'].includes(bill.note.toLowerCase())" class="pt-2 mt-2 border-t border-gray-100 text-xs text-gray-500 italic">
                                        Note: {{ bill.note }}
                                    </div>
                                </div>
                                <div class="flex gap-2 mt-3">
                                    <!-- Action for Paid App Orders -->
                                    <div v-if="bill.payment_status === 'paid'" class="flex flex-col gap-3 flex-1">
                                        <div class="flex gap-2">
                                            <!-- Manual WhatsApp Button (Only if no phone) -->
                                            <button 
                                                v-if="!bill.customer_phone && !bill.customer?.phone"
                                                @click="toggleNotification(bill)"
                                                class="bg-green-100 text-green-700 p-2 rounded-lg hover:bg-green-200 transition h-10 w-10 flex items-center justify-center aspect-square shrink-0"
                                                :class="{'bg-green-200 ring-2 ring-green-500/20': notificationOpenId === bill.id}"
                                                title="Notify Customer via WhatsApp"
                                            >
                                                <MessageCircleIcon class="w-5 h-5" />
                                            </button>

                                            <button 
                                                @click="handleProcess(bill)"
                                                class="flex-1 bg-primary text-white text-sm font-bold py-2 rounded-lg hover:bg-[#004d34] transition flex items-center justify-center gap-2 h-10"
                                            >
                                                <PrinterIcon class="w-4 h-4" />
                                                <span v-if="bill.customer_phone || bill.customer?.phone">Selesai & Notify</span>
                                                <span v-else>Process / Print</span>
                                            </button>
                                        </div>

                                        <!-- WhatsApp Input Slide Down -->
                                        <div 
                                            v-if="notificationOpenId === bill.id"
                                            class="bg-gray-50 rounded-xl p-3 border border-gray-100 animate-in slide-in-from-top-2 fade-in"
                                        >
                                            <div class="flex items-center justify-between mb-2">
                                                 <label class="text-[10px] font-bold text-gray-500 uppercase tracking-wider">Kirim Notifikasi WhatsApp</label>
                                                 <button @click="notificationOpenId = null" class="text-gray-400 hover:text-gray-600"><XIcon class="w-3 h-3" /></button>
                                            </div>
                                            <div class="flex gap-2">
                                                <div class="relative flex-1">
                                                    <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xs font-bold">+62</span>
                                                    <input 
                                                        ref="phoneInput"
                                                        v-model="notificationPhone" 
                                                        type="tel"
                                                        placeholder="812..." 
                                                        class="w-full pl-10 pr-3 py-2 bg-white border border-gray-200 rounded-lg text-sm font-bold focus:ring-1 focus:ring-green-500 focus:border-green-500 outline-none"
                                                        @keyup.enter="sendNotification(bill)"
                                                    />
                                                </div>
                                                <button 
                                                    @click="sendNotification(bill)"
                                                    class="bg-primary hover:bg-[#004d34] text-white px-4 rounded-lg flex items-center justify-center transition disabled:opacity-50 font-bold text-sm"
                                                    :disabled="!notificationPhone || sending"
                                                >
                                                    <LoaderIcon v-if="sending" class="w-4 h-4 animate-spin" />
                                                    <span v-else>Send</span>
                                                </button>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Action for Open Bills -->
                                    <template v-else>
                                        <button 
                                            @click="$emit('load', bill)"
                                            class="flex-1 bg-primary text-white text-sm font-bold py-2 rounded-lg hover:bg-[#004d34] transition"
                                        >
                                            Resume Payment
                                        </button>
                                        <button 
                                            @click.stop="$emit('cancel', bill)"
                                            class="px-3 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition"
                                        >
                                            <XCircleIcon class="w-4 h-4" />
                                        </button>
                                    </template>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </Transition>
    </Teleport>
</template>

<script setup>
import { ref, onMounted, watch, nextTick } from 'vue';
import { XIcon, LoaderIcon, ReceiptIcon, XCircleIcon, PrinterIcon, Share2Icon, SendIcon, MessageCircleIcon } from 'lucide-vue-next';
import { formatCurrency } from '../../utils/format';
import api from '../../api/axios';
import { useProductDisplay } from '../../composables/useProductDisplay';

import { useToast } from 'vue-toastification';

import { useAuthStore } from '../../stores/auth';

const props = defineProps({
    isOpen: Boolean
});

const emit = defineEmits(['close', 'load', 'cancel', 'print']);
const toast = useToast();
const authStore = useAuthStore();
const { getVisibleModifiers } = useProductDisplay();

const loading = ref(false);
const pendingBills = ref([]);
const notificationOpenId = ref(null);
const notificationPhone = ref('');
const sending = ref(false);
const phoneInput = ref(null);

const fetchPendingBills = async () => {
    loading.value = true;
    try {
        const response = await api.get('/admin/orders/pending');
        const resData = response.data?.data || response.data || {};
        pendingBills.value = Array.isArray(resData) ? resData : (resData.data || []);
    } catch (e) {
        console.error('Failed to fetch pending bills:', e);
    } finally {
        loading.value = false;
    }
};

const formatTime = (date) => {
    return new Date(date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
};

const toggleNotification = (bill) => {
    if (notificationOpenId.value === bill.id) {
        notificationOpenId.value = null;
    } else {
        notificationOpenId.value = bill.id;
        notificationPhone.value = bill.customer?.phone || '';
        nextTick(() => {
            if (phoneInput.value) {
                // If it's an array (v-for), get the last one or handle appropriately. 
                // Since v-if="notificationOpenId === bill.id" makes only ONE input visible at a time roughly in the same DOM tree position, 
                // but inside v-for, Vue 3 refs inside v-for are arrays.
                // However, here the input is inside v-for="bill in pendingBills".
                // So phoneInput will be an array of all inputs. We need to find the one visible. 
                // Alternatively, simpler here: since only one is open, we can try to focus the first one found or iterate.
                // Re-reading logic: phoneInput ref inside v-for will be array. 
                if (Array.isArray(phoneInput.value)) {
                    const input = phoneInput.value.find(el => el && el.offsetParent !== null); // find visible
                    input?.focus();
                } else {
                    phoneInput.value?.focus();
                }
            }
        });
    }
};

const handleProcess = async (bill) => {
    // Attribute order to current cashier
    try {
        await api.put(`/orders/${bill.id}`, {
            user_id: authStore.user?.id,
            payment_status: 'paid'
        });
    } catch (e) {
        console.error("Failed to attribute order", e);
    }

    const phone = bill.customer_phone || bill.customer?.phone;
    if (phone) {
        // Send notification in background (no await)
        sendNotification(bill, phone);
    }
    emit('print', bill);
};

const sendNotification = async (bill, phoneOverride = null) => {
    const phone = phoneOverride || notificationPhone.value;
    if (!phone) return;
    
    sending.value = true;
    try {
        await api.post(`/admin/orders/${bill.id}/notify`, {
            phone: phone
        });
        toast.success(`Notification sent to ${bill.customer_name}`);
        notificationOpenId.value = null;
    } catch (e) {
        toast.error('Failed to send WhatsApp notification');
        console.error(e);
    } finally {
        sending.value = false;
    }
};

watch(() => props.isOpen, (val) => {
    if (val) fetchPendingBills();
});
</script>

<style scoped>
.fade-enter-active, .fade-leave-active { transition: opacity 0.2s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
