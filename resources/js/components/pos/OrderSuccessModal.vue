<template>
    <div v-if="isOpen" class="fixed inset-0 z-60 flex items-center justify-center p-4">
        <!-- Backdrop -->
        <div class="fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity"></div>

        <!-- Modal Content -->
        <div class="bg-gray-100 rounded-4xl shadow-2xl w-full max-w-[480px] relative z-10 overflow-hidden flex flex-col max-h-[90vh]">
            
            <!-- Success Header -->
            <div class="text-center pt-8 pb-4 px-6">
                <!-- Animated Check Icon -->
                <div class="w-20 h-20 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4 animate-bounce-slow">
                    <div class="w-14 h-14 bg-primary rounded-full flex items-center justify-center shadow-lg shadow-primary/30">
                        <CheckIcon class="w-8 h-8 text-white" stroke-width="4" />
                    </div>
                </div>
                <h2 class="text-2xl font-bold text-gray-900">Payment Successful</h2>
                <p class="text-gray-500 text-sm mt-1">Transaction #{{ order?.order_number }} completed</p>
            </div>

            <!-- Receipt Card -->
            <div class="mx-8 mb-6 bg-white rounded-2xl shadow-sm border border-gray-100 flex-1 overflow-hidden flex flex-col relative">
                 <!-- Receipt Top Decoration -->
                 <div class="absolute top-0 left-0 right-0 h-1.5 bg-linear-to-r from-primary/80 to-primary"></div>

                <div class="p-6 flex-1 overflow-y-auto no-scrollbar">
                    <!-- Store Brand -->
                    <div class="text-center mb-6">
                        <img 
                            v-if="settings.store_logo" 
                            :src="settings.store_logo" 
                            class="h-14 mx-auto mb-2 object-contain"
                            style="filter: brightness(0) saturate(100%) invert(38%) sepia(20%) saturate(836%) hue-rotate(45deg) brightness(96%) contrast(89%)"
                        />
                        <div v-else class="w-12 h-12 border-[3px] border-primary rounded-full flex items-center justify-center mx-auto mb-2 text-primary">
                            <CoffeeIcon class="w-6 h-6" />
                        </div>
                        <h3 class="font-bold text-gray-900 text-lg leading-tight">{{ settings.store_name || 'Ruang Bincang' }}</h3>
                        <p class="text-[0.65rem] text-gray-400 font-bold mt-1 max-w-[250px] mx-auto leading-snug">{{ settings.store_address || 'Coffee & Roastery' }}</p>
                    </div>

                    <!-- Items List -->
                    <div class="space-y-3 mb-6">
                        <div v-for="item in order?.items" :key="item.id" class="flex justify-between items-start text-sm">
                            <div class="pr-4">
                                <p class="font-bold text-gray-800 text-base leading-tight">{{ getProductName(item) }}</p>
                                <!-- Modifiers -->
                                <div v-if="getVisibleModifiers(item) && getVisibleModifiers(item).length" class="flex flex-wrap gap-1 mt-1">
                                    <span v-for="(mod, idx) in getVisibleModifiers(item)" :key="idx" class="text-xs text-gray-500 bg-gray-50 px-1.5 py-0.5 rounded">
                                        {{ getModifierDisplayName(mod) }}
                                    </span>
                                </div>
                                <p class="text-xs text-gray-400 mt-0.5" v-if="item.quantity > 1">Qty: {{ item.quantity }} x {{ formatCurrency(item.price) }}</p>
                            </div>
                            <span class="font-bold text-gray-900 shrink-0 text-base">{{ formatCurrency(item.total_price || (item.price * item.quantity)) }}</span>
                        </div>
                    </div>

                    <!-- Divider -->
                    <div class="border-t-2 border-dashed border-gray-100 my-5"></div>

                    <!-- Totals -->
                    <div class="space-y-2.5 text-sm">
                        <div class="flex justify-between">
                            <span class="text-gray-500 font-medium">Subtotal</span>
                            <span class="text-gray-900 font-bold">{{ formatCurrency(order?.subtotal) }}</span>
                        </div>
                        <div v-if="order?.discount_amount > 0" class="flex justify-between text-green-600">
                            <span class="font-medium">Discount</span>
                            <span class="font-bold">-{{ formatCurrency(order?.discount_amount) }}</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-gray-500 font-medium">Tax</span>
                             <span class="text-gray-900 font-bold">{{ formatCurrency(order?.tax_amount) }}</span>
                        </div>
                        <div class="flex justify-between pt-3 items-end">
                            <span class="font-bold text-gray-900 text-lg">Total Paid</span>
                            <span class="font-bold text-primary text-2xl">{{ formatCurrency(order?.grand_total) }}</span>
                        </div>
                         <div class="flex justify-between text-sm pt-1" v-if="changeAmount > 0">
                            <span class="text-gray-500 font-medium">Change</span>
                            <span class="font-bold text-gray-700">{{ formatCurrency(changeAmount) }}</span>
                        </div>
                    </div>
                </div>
                
                <!-- Receipt Footer -->
                <div class="bg-gray-50 px-6 py-4 text-[11px] text-gray-400 flex justify-between items-center border-t border-gray-100 font-medium uppercase tracking-wide">
                    <span>{{ formatDate(new Date()) }}</span>
                    <span class="flex items-center gap-1.5 bg-white px-2 py-1 rounded border border-gray-100">
                        <CreditCardIcon class="w-3.5 h-3.5" v-if="order?.payment_method !== 'cash'" />
                        <BanknoteIcon class="w-3.5 h-3.5" v-else />
                        {{ order?.payment_method }}
                    </span>
                </div>
            </div>

            <!-- Action Buttons -->
            <div class="bg-white p-6 rounded-t-[2.5rem] shadow-[0_-4px_30px_rgba(0,0,0,0.08)] space-y-3 z-20">
                <button 
                    @click="$emit('new-order')"
                    class="w-full bg-primary hover:bg-[#004d34] text-white font-bold py-4 rounded-2xl shadow-lg shadow-primary/25 transition transform active:scale-[0.98] text-lg"
                >
                    New Order
                </button>
                
                <div class="flex gap-3">
                    <button 
                        @click="$emit('print')"
                        class="flex-1 bg-white border-2 border-gray-100 hover:bg-gray-50 text-gray-700 font-bold py-3.5 rounded-2xl transition flex items-center justify-center gap-2"
                    >
                        <PrinterIcon class="w-5 h-5" />
                        Print
                    </button>
                    <!-- WhatsApp Button -->
                    <button 
                        @click="toggleWaInput"
                        class="flex-1 bg-white border-2 border-gray-100 hover:bg-gray-50 text-gray-700 font-bold py-3.5 rounded-2xl transition flex items-center justify-center gap-2 relative overflow-hidden"
                        :class="{'bg-primary/5 border-primary/20 text-primary': showWaInput}"
                    >
                        <component :is="showWaInput ? XIcon : Share2Icon" class="w-5 h-5" />
                        {{ showWaInput ? 'Cancel' : 'Invoice' }}
                    </button>
                </div>

                <!-- WhatsApp Input Slide Down -->
                 <div v-if="showWaInput" class="pt-2 animate-in slide-in-from-bottom-2 fade-in duration-300">
                     <label class="block text-[10px] font-bold text-gray-400 mb-1.5 ml-1 uppercase tracking-wider">WhatsApp Number</label>
                    <div class="flex gap-2">
                        <div class="relative flex-1">
                            <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 text-sm font-bold">+62</span>
                            <input 
                                v-model="waNumber" 
                                type="tel" 
                                placeholder="812345678" 
                                class="w-full pl-12 pr-4 py-3.5 bg-gray-50 border-2 border-gray-100 rounded-2xl text-sm font-bold text-gray-900 focus:ring-0 focus:border-primary outline-none transition-colors"
                                @keyup.enter="sendToWa"
                            />
                        </div>
                        <button 
                            @click="sendToWa"
                            class="bg-primary hover:bg-[#004d34] text-white px-5 rounded-2xl shadow-lg shadow-primary/25 transition transform active:scale-95 flex items-center justify-center disabled:opacity-50 disabled:cursor-not-allowed"
                            :disabled="!waNumber || sending"
                        >
                            <LoaderIcon v-if="sending" class="w-5 h-5 animate-spin" />
                            <SendIcon v-else class="w-5 h-5" />
                        </button>
                    </div>
                </div>
            </div>

        </div>
    </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { 
    CheckIcon, PrinterIcon, Share2Icon, CoffeeIcon, 
    CreditCardIcon, BanknoteIcon, SendIcon, XIcon, LoaderIcon 
} from 'lucide-vue-next';
import { formatCurrency } from '../../utils/format';
import { format } from 'date-fns';
import { usePosStore } from '../../stores/pos';
import api from '../../api/axios';
import { useToast } from 'vue-toastification';
import { useProductDisplay } from '../../composables/useProductDisplay';

const { getProductName, getVisibleModifiers, getModifierDisplayName } = useProductDisplay();
const props = defineProps({
    isOpen: Boolean,
    order: Object
});

defineEmits(['print', 'new-order']);

const posStore = usePosStore();
const toast = useToast();
const settings = computed(() => posStore.settings || {});
const showWaInput = ref(false);
const waNumber = ref('');

const changeAmount = computed(() => props.order?.change || 0);

const toggleWaInput = () => {
    showWaInput.value = !showWaInput.value;
    if (showWaInput.value && props.order) {
        // Auto-fill phone
        let phone = '';
        if (props.order.customer && props.order.customer.phone) {
             phone = props.order.customer.phone;
        } else if (props.order.customer_phone) {
             phone = props.order.customer_phone;
        }
        
        if (phone) {
             phone = phone.replace(/\D/g, '');
             if (phone.startsWith('62')) phone = phone.substring(2);
             else if (phone.startsWith('0')) phone = phone.substring(1);
             waNumber.value = phone;
        } else {
             waNumber.value = '';
        }
    }
};

const formatDate = (date) => {
    return format(date, 'MMM dd, yyyy • HH:mm');
};

const sending = ref(false);

const sendToWa = async () => {
    if (!waNumber.value) return;
    const order = props.order;
    if (!order) return;

    let phone = waNumber.value.replace(/\D/g, '');
    if (phone.startsWith('0')) {
        phone = '62' + phone.substring(1);
    } else if (!phone.startsWith('62')) {
        phone = '62' + phone;
    }
    
    sending.value = true;
    try {
        await api.post(`/orders/${order.id}/whatsapp-receipt`, {
            phone: phone
        });
        toast.success(`Receipt sent to +${phone}`);
        showWaInput.value = false;
    } catch (e) {
        console.error(e);
        toast.error(e.response?.data?.message || "Failed to send receipt");
    } finally {
        sending.value = false;
    }
};
</script>

<style scoped>
.no-scrollbar::-webkit-scrollbar {
    display: none;
}
.no-scrollbar {
    -ms-overflow-style: none;
    scrollbar-width: none;
}
.animate-bounce-slow {
    animation: bounce 2s infinite;
}
@keyframes bounce {
    0%, 100% {
        transform: translateY(-5%);
        animation-timing-function: cubic-bezier(0.8, 0, 1, 1);
    }
    50% {
        transform: translateY(0);
        animation-timing-function: cubic-bezier(0, 0, 0.2, 1);
    }
}
</style>
