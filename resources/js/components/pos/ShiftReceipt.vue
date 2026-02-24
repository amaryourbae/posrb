<template>
    <div id="shift-receipt" class="hidden print:block font-mono text-[10px] leading-tight text-black bg-white" v-if="shift">
        <div class="w-[58mm] mx-auto print:w-full font-medium px-4 py-4">
            
            <!-- Header -->
            <div class="text-center mb-1 flex flex-col items-center">
                <img v-if="settings.store_logo" :src="settings.store_logo" class="h-10 w-auto object-contain mb-1 brightness-0" />
                <h1 class="font-bold text-sm mb-1">{{ settings.store_name || 'Ruang Bincang Coffee' }}</h1>
                <p v-if="settings.store_address" class="px-2">{{ settings.store_address }}</p>

                <p class="mt-0.5" v-if="settings.store_phone">{{ settings.store_phone }}</p>
            </div>

            <div class="text-center mb-2">
                <h2 class="font-bold text-sm">SHIFT SUMMARY</h2>
                <p class="text-[9px]">{{ formatDate(new Date()) }}</p>
            </div>

            <div class="border-b border-black border-dotted my-2"></div>

            <!-- Shift Info -->
            <div class="mb-2 space-y-1">
                <div class="flex justify-between">
                    <span>Cashier:</span>
                    <span class="font-bold">{{ shift.user?.name || 'Unknown' }}</span>
                </div>
                <div class="flex justify-between">
                    <span>Start:</span>
                    <span>{{ formatTime(shift.start_time) }}</span>
                </div>
                <div class="flex justify-between">
                    <span>End:</span>
                    <span>{{ formatTime(shift.end_time || new Date()) }}</span>
                </div>
                <div class="flex justify-between">
                    <span>Duration:</span>
                    <span>{{ getDuration(shift.start_time, shift.end_time) }}</span>
                </div>
            </div>

            <div class="border-b border-black border-dotted my-2"></div>

            <!-- Financials -->
            <div class="mb-2 space-y-1">
                <div class="flex justify-between">
                    <span>Starting Cash:</span>
                    <span>{{ formatCurrency(shift.starting_cash) }}</span>
                </div>
                <div class="flex justify-between">
                    <span>Cash Sales:</span>
                    <span>+ {{ formatCurrency(shift.current_cash_sales) }}</span>
                </div>
                <div class="flex justify-between" v-if="shift.current_cash_refunds > 0">
                    <span>Refunds:</span>
                    <span>- {{ formatCurrency(shift.current_cash_refunds) }}</span>
                </div>
                <div class="border-b border-gray-400 my-1"></div>
                <div class="flex justify-between font-bold">
                    <span>Expected Cash:</span>
                    <span>{{ formatCurrency(shift.ending_cash_expected) }}</span>
                </div>
                 <div class="flex justify-between font-bold">
                    <span>Actual Cash:</span>
                    <span>{{ formatCurrency(shift.ending_cash_actual) }}</span>
                </div>
                 <div class="flex justify-between font-bold" :class="shift.difference != 0 ? 'text-black' : ''">
                    <span>Difference:</span>
                    <span>{{ formatCurrency(shift.difference) }}</span>
                </div>
            </div>

            <div class="border-b border-black border-dotted my-2"></div>

            <!-- Item Sales Summary -->
            <div class="mb-2">
                <p class="font-bold mb-1 uppercase text-center">Items Sold (Paid)</p>
                <div v-if="shift.sales_summary && shift.sales_summary.length">
                    <div v-for="(item, idx) in shift.sales_summary" :key="idx" class="flex justify-between mb-0.5">
                        <span class="flex-1">{{ item.qty }}x {{ item.name }}</span>
                        <span>{{ formatCurrency(item.total) }}</span>
                    </div>
                </div>
                <div v-else class="text-center text-gray-400 italic">No sales recorded</div>
            </div>
            
             <div class="border-b border-black border-dotted my-2"></div>
             
             <!-- Notes -->
             <div v-if="shift.note" class="mb-2">
                <p class="font-bold">Note:</p>
                <p class="italic">{{ shift.note }}</p>
             </div>

            <div class="text-center mt-4">
                <p class="font-bold">** END OF REPORT **</p>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { usePosStore } from '../../stores/pos';
import { format } from 'date-fns';

const props = defineProps({
    shift: Object
});

const posStore = usePosStore();
const settings = computed(() => posStore.settings || {});

const formatCurrency = (val) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(val || 0);
};

const formatDate = (d) => {
    if(!d) return '';
    return format(new Date(d), 'dd/MM/yyyy HH:mm');
};

const formatTime = (d) => {
    if(!d) return '';
    return format(new Date(d), 'HH:mm');
};

const getDuration = (start, end) => {
    if (!start) return '-';
    const s = new Date(start);
    const e = end ? new Date(end) : new Date();
    const diff = e - s;
    
    const hrs = Math.floor(diff / 3600000);
    const mins = Math.floor((diff % 3600000) / 60000);
    return `${hrs}h ${mins}m`;
};
</script>

<style scoped>
@media print {
    body * {
        visibility: hidden;
    }
    #shift-receipt, #shift-receipt * {
        visibility: visible;
    }
    #shift-receipt {
        position: absolute;
        left: 0;
        top: 0;
        width: 100%;
        margin: 0;
        padding: 0;
    }
}
</style>
