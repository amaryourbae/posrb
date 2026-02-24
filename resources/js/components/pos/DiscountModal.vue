<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <!-- Backdrop -->
        <div class="fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity" @click="$emit('close')"></div>

        <!-- Modal Content -->
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-md relative z-10 flex flex-col max-h-[85vh]">
            
            <!-- Header -->
            <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
                <h3 class="font-bold text-lg text-gray-900">Select Discount</h3>
                <button @click="$emit('close')" class="p-2 hover:bg-gray-100 rounded-full transition text-gray-500">
                    <XIcon class="w-5 h-5" />
                </button>
            </div>

            <!-- Discount List -->
            <div class="flex-1 overflow-y-auto px-6 py-4 space-y-3">
                <div v-if="loading" class="space-y-3">
                    <div v-for="i in 3" :key="i" class="h-20 bg-gray-100 rounded-xl animate-pulse"></div>
                </div>
                
                <div v-else-if="discounts.length === 0" class="text-center py-8 text-gray-500">
                    <TicketIcon class="w-12 h-12 mx-auto mb-2 text-gray-300" />
                    <p>No active discounts available</p>
                </div>

                <div 
                    v-for="discount in discounts" 
                    :key="discount.id"
                    class="border rounded-xl p-4 transition cursor-pointer relative overflow-hidden group"
                    :class="[
                        isSelected(discount) ? 'border-primary bg-primary/5 ring-1 ring-primary' : 'border-gray-200 hover:border-primary/50 hover:shadow-sm',
                        isApplicable(discount) ? '' : 'opacity-60 cursor-not-allowed bg-gray-50'
                    ]"
                    @click="handleSelect(discount)"
                >
                    <div class="flex justify-between items-start">
                        <div>
                            <h4 class="font-bold text-gray-800">{{ discount.name }}</h4>
                            <p class="text-xs text-gray-500 font-mono mt-0.5 bg-gray-100 inline-block px-1.5 py-0.5 rounded">{{ discount.code }}</p>
                        </div>
                        <div class="text-right">
                            <span class="font-bold text-lg text-primary">
                                {{ discount.type === 'fixed' ? formatCurrency(discount.value) : `${discount.value}%` }}
                            </span>
                            <span class="block text-[10px] text-gray-400 uppercase font-bold tracking-wider">OFF</span>
                        </div>
                    </div>
                    
                    <div class="mt-3 pt-3 border-t border-gray-100 flex justify-between items-center text-xs">
                        <span v-if="discount.min_purchase > 0" class="text-gray-500">
                            Min. purchase: {{ formatCurrency(discount.min_purchase) }}
                        </span>
                        <span v-else class="text-gray-500">No minimum purchase</span>

                        <span v-if="!isApplicable(discount)" class="text-red-500 font-bold">
                            Not applicable
                        </span>
                        <span v-else-if="isSelected(discount)" class="text-primary font-bold flex items-center gap-1">
                            <CheckIcon class="w-3 h-3" /> Selected
                        </span>
                    </div>
                </div>
            </div>

            <!-- Warning/Info Footer -->
            <div v-if="activeDiscount && !isApplicable(activeDiscount)" class="px-6 py-2 bg-yellow-50 text-xs text-yellow-700 border-t border-yellow-100 flex items-center gap-2">
                <AlertTriangleIcon class="w-3 h-3" />
                Current selection requirements not met. Discount will not apply.
            </div>

            <!-- Action Footer -->
            <div class="p-6 border-t border-gray-100 bg-gray-50 rounded-b-2xl flex gap-3">
                 <button 
                    v-if="activeDiscount"
                    @click="handleRemove"
                    class="px-4 py-3 border border-red-200 text-red-600 font-bold rounded-xl hover:bg-red-50 transition"
                >
                    Remove
                </button>
                <button 
                    @click="$emit('close')"
                    class="flex-1 bg-gray-900 text-white font-bold py-3 rounded-xl hover:bg-gray-800 transition shadow-lg shadow-gray-900/10"
                >
                    Close
                </button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { XIcon, TicketIcon, CheckIcon, AlertTriangleIcon } from 'lucide-vue-next';
import { usePosStore } from '../../stores/pos';
import { formatCurrency } from '../../utils/format';

const props = defineProps({
    isOpen: Boolean
});

const emit = defineEmits(['close']);
const posStore = usePosStore();

const discounts = computed(() => posStore.discounts);
const activeDiscount = computed(() => posStore.activeDiscount);
const subTotal = computed(() => posStore.subTotal);
const loading = ref(false);

const isSelected = (discount) => activeDiscount.value?.id === discount.id;

const isApplicable = (discount) => {
    if (!discount) return false;
    if (discount.min_purchase && subTotal.value < parseFloat(discount.min_purchase)) {
        return false;
    }
    return true;
};

const handleSelect = (discount) => {
    if (!isApplicable(discount)) {
        // Optional: Show toast explaining why
        return;
    }
    
    if (isSelected(discount)) {
        posStore.removeDiscount();
    } else {
        posStore.applyDiscount(discount);
    }
};

const handleRemove = () => {
    posStore.removeDiscount();
};

onMounted(() => {
    loading.value = true;
    posStore.fetchDiscounts().finally(() => {
        loading.value = false;
    });
});
</script>
