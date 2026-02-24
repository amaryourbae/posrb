<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <!-- Backdrop -->
        <div class="fixed inset-0 bg-black/40 backdrop-blur-sm transition-opacity" @click="$emit('close')"></div>

        <!-- Modal -->
        <div class="bg-white rounded-3xl shadow-2xl w-full max-w-lg relative z-10 overflow-hidden flex flex-col max-h-[90vh]">
            <!-- Header -->
            <div class="px-8 py-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                <div>
                    <h2 class="text-2xl font-bold text-gray-900">Payment</h2>
                    <p class="text-sm text-gray-500">Total Bill: <span class="font-bold text-primary text-lg">{{ formatCurrency(totalAmount) }}</span></p>
                </div>
                <button @click="$emit('close')" class="p-2 hover:bg-gray-100 rounded-full transition">
                    <XIcon class="w-6 h-6 text-gray-400" />
                </button>
            </div>

            <div class="p-8 overflow-y-auto">
                <!-- Payment Methods -->
                <div class="mb-8">
                    <label class="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-3">Select Payment Method</label>
                    <div class="grid grid-cols-3 gap-3">
                        <button 
                            v-for="method in methods" 
                            :key="method.id"
                            @click="selectMethod(method.id)"
                            class="flex flex-col items-center justify-center gap-2 p-4 rounded-2xl border-2 transition hover:bg-gray-50 bg-white"
                            :class="selectedMethod === method.id ? 'border-primary bg-primary/5 text-primary' : 'border-gray-100 text-gray-500'"
                        >
                            <component :is="method.icon" class="w-8 h-8" />
                            <span class="text-sm font-bold">{{ method.label }}</span>
                        </button>
                    </div>
                </div>

                <!-- Cash Payment Section -->
                <div v-if="selectedMethod === 'cash'" class="space-y-6">
                    <div>
                        <label class="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-3">Amount Paid</label>
                        <div class="relative">
                            <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 font-bold">Rp</span>
                            <input 
                                v-model="amountPaid"
                                type="number" 
                                class="w-full pl-12 pr-4 py-4 bg-gray-50 border border-gray-200 rounded-2xl font-bold text-xl text-gray-900 focus:ring-2 focus:ring-primary focus:border-primary outline-none transition"
                                placeholder="0"
                            />
                        </div>
                    </div>

                    <!-- Quick Amounts -->
                    <div class="grid grid-cols-2 gap-2">
                        <button 
                            v-for="amount in quickAmounts" 
                            :key="amount"
                            @click="amountPaid = amount" 
                            class="py-3 px-3 rounded-xl bg-gray-100 text-gray-700 text-sm font-bold hover:bg-gray-200 transition"
                            :class="amountPaid === amount ? 'bg-primary text-white hover:bg-primary' : ''"
                        >
                            {{ amount === totalAmount ? 'Exact' : formatCurrency(amount) }}
                        </button>
                    </div>

                    <!-- Change Display -->
                    <div class="p-4 bg-green-50 rounded-2xl border border-green-100 flex justify-between items-center">
                        <span class="text-green-700 font-bold text-sm">Change Return</span>
                        <span class="text-2xl font-bold text-green-700">{{ formatCurrency(change) }}</span>
                    </div>
                </div>

                <!-- QRIS Section -->
                <div v-if="selectedMethod === 'qris'" class="text-center py-8">
                    <div class="w-48 h-48 bg-gray-900 rounded-2xl mx-auto flex items-center justify-center text-white mb-4">
                        <QrCodeIcon class="w-24 h-24" />
                    </div>
                    <p class="text-sm text-gray-500 font-medium">Scan QR Code to Pay</p>
                </div>
            </div>

            <!-- Footer -->
            <div class="p-6 border-t border-gray-100 bg-white">
                <button 
                    @click="processPayment"
                    :disabled="!isValid"
                    class="w-full py-4 rounded-xl font-bold text-lg text-white shadow-lg shadow-primary/30 transition transform active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                     :class="isValid ? 'bg-primary hover:bg-[#004d34]' : 'bg-gray-400'"
                >
                    <span v-if="loading" class="animate-spin w-5 h-5 border-2 border-white border-t-transparent rounded-full"></span>
                    <span>{{ loading ? 'Processing...' : `Confirm Payment` }}</span>
                </button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { XIcon, BanknoteIcon, QrCodeIcon, CreditCardIcon } from 'lucide-vue-next';
import { formatCurrency } from '../../utils/format';

const props = defineProps({
    isOpen: Boolean,
    totalAmount: Number,
    loading: Boolean
});

const emit = defineEmits(['close', 'process']);

const selectedMethod = ref('cash');
const amountPaid = ref(0);

const methods = [
    { id: 'cash', label: 'Cash', icon: BanknoteIcon },
    { id: 'qris', label: 'QRIS', icon: QrCodeIcon },
    { id: 'debit', label: 'Debit/Credit', icon: CreditCardIcon },
];

const selectMethod = (id) => {
    selectedMethod.value = id;
    if (id === 'cash') {
        amountPaid.value = 0; // Reset or maybe set to total default?
    } else {
        amountPaid.value = props.totalAmount; // Auto-fill for digital payments
    }
};

const change = computed(() => {
    return Math.max(0, amountPaid.value - props.totalAmount);
});

const isValid = computed(() => {
    if (selectedMethod.value === 'cash') {
        return amountPaid.value >= props.totalAmount;
    }
    return true; // For other methods usually we wait for callback, but here manual confirm
});

const quickAmounts = computed(() => {
    const total = props.totalAmount;
    const suggestions = new Set([total]);

    // Next 10,000
    if (total % 10000 !== 0) suggestions.add(Math.ceil(total / 10000) * 10000);

    // Next 20,000
    suggestions.add(Math.ceil(total / 20000) * 20000);

    // Next 50,000
    suggestions.add(Math.ceil(total / 50000) * 50000);

    // Next 100,000
    suggestions.add(Math.ceil(total / 100000) * 100000);

    return Array.from(suggestions)
        .filter(amount => amount >= total)
        .sort((a, b) => a - b)
        .slice(0, 4);
});

const processPayment = () => {
    emit('process', {
        method: selectedMethod.value,
        amount_paid: parseFloat(amountPaid.value),
        change: change.value
    });
};
</script>
