<template>
    <div id="pos-receipt" class="hidden print:block font-mono text-[10px] leading-tight text-black bg-white" v-if="order">
        <!-- Receipt Container -->
        <div class="w-[58mm] mx-auto print:w-full font-medium px-4 py-4">
            
            <!-- Header -->
            <div class="text-center mb-1 flex flex-col items-center">
                <img v-if="settings.store_logo" :src="settings.store_logo" class="h-10 w-auto object-contain mb-1 brightness-0" />
                <h1 class="font-bold text-sm mb-1">{{ settings.store_name || 'Ruang Bincang Coffee' }}</h1>
                <p v-if="settings.store_address" class="px-2">{{ settings.store_address }}</p>

                <p class="mt-0.5" v-if="settings.store_phone">{{ settings.store_phone }}</p>
            </div>
            <!-- Dotted Divider -->
            <div class="border-b border-black border-dotted my-2"></div>

            <!-- Big Order Number -->
            <div class="text-center mb-2">
                <h2 class="text-xl font-bold">{{ order.order_number?.split('-').pop() || order.id?.toString().slice(-4) }}</h2>
                <p class="text-[10px]">{{ order.order_type === 'dine_in' ? 'Dine In' : 'Pick up Order' }}</p>
            </div>

            <!-- Order Info -->
            <div class="mb-2">
                <p>Nama Customer: {{ order.customer_name || 'Guest' }}</p>
                <p>{{ formatDateFull(order.created_at || new Date()) }}</p>
                <p>#{{ order.order_number }}</p>
            </div>

            <!-- Dotted Divider -->
            <div class="border-b border-black border-dotted my-1"></div>

            <!-- Items Header -->
            <div class="flex justify-between font-bold mb-1">
                <span>Order</span>
                <span>Total Order: {{ order.items?.length || 0 }}</span>
            </div>

            <!-- Items -->
            <div class="mb-2">
                <div v-for="item in order.items" :key="item.id" class="flex justify-between mb-1 items-start">
                    <div class="flex gap-1">
                        <span class="w-4 shrink-0">{{ item.quantity }}x</span>
                        <div class="flex flex-col">
                            <span>{{ getProductName(item) }}</span>
                            <span v-if="getVisibleModifiers(item) && getVisibleModifiers(item).length" class="text-[9px] text-gray-500">
                                {{ getVisibleModifiers(item).map(m => m.option_name || m.name).join(', ') }}
                            </span>
                             <span v-if="getDisplayNote(item)" class="text-[9px] italic">"{{ getDisplayNote(item) }}"</span>
                        </div>
                    </div>
                    <span class="shrink-0">{{ formatNumber(item.total_price || (item.price * item.quantity)) }}</span>
                </div>
            </div>

            <!-- Divider -->
            <div class="border-b border-gray-400 my-1"></div>

            <!-- Subtotals -->
            <div class="flex justify-between mb-1">
                <span>Sub Total</span>
                <span>Rp {{ formatNumber(order.subtotal) }}</span>
            </div>
            
            <div class="flex justify-between mb-1" v-if="order.discount_amount > 0">
                <span>Discount</span>
                <span>-Rp {{ formatNumber(order.discount_amount) }}</span>
            </div>

            <div class="flex justify-between font-bold text-xs mb-2">
                <span>SUBTOTAL</span>
                <span>Rp {{ formatNumber(order.grand_total - order.tax_amount) }}</span> 
            </div>

            <!-- Divider -->
            <div class="border-b border-black border-dotted my-1"></div>

             <!-- Tax Breakdown -->
            <div class="flex justify-between text-[9px] mb-0.5" v-if="order.tax_amount > 0">
                <span>Net sales</span>
                <span>Rp {{ formatNumber(order.subtotal - order.discount_amount) }}</span>
            </div>
            <div class="flex justify-between text-[9px] mb-0.5" v-if="order.tax_amount > 0">
                <span>PB1 {{ settings.tax_rate }}%</span> 
                <span>Rp {{ formatNumber(order.tax_amount) }}</span>
            </div>
            
            <!-- Divider -->
            <div class="border-b border-black border-dotted my-1"></div>

            <div class="flex justify-between font-bold text-sm mb-1">
                <span>Total Pembayaran</span>
                <span>Rp {{ formatNumber(order.grand_total) }}</span>
            </div>
             <div class="flex justify-between text-xs mb-2">
                <span>Metode Pembayaran</span>
                <span class="uppercase">{{ order.payment_method }}</span>
            </div>
            <div class="border-b border-black border-dotted my-1"></div>


            <!-- Footer -->
            <div class="text-center mt-3 pb-2">
                <p class="text-lg mb-1">Terima Kasih</p>
                <p class="px-4">{{ settings?.receipt_footer || 'Dapatkan 1 minuman gratis dan berbagai keuntungan dengan mengumpulkan poin.' }}</p>
                <p class="mt-1" v-if="settings?.store_website">{{ settings.store_website }}</p>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { usePosStore } from '../../stores/pos';
import { useAuthStore } from '../../stores/auth';
import { format } from 'date-fns';
import { id } from 'date-fns/locale';
import { useProductDisplay } from '../../composables/useProductDisplay';

const props = defineProps({
    order: Object
});
const { getProductName, getVisibleModifiers } = useProductDisplay();

const posStore = usePosStore();
const authStore = useAuthStore();
const settings = computed(() => posStore.settings);

const formatNumber = (num) => {
    return new Intl.NumberFormat('id-ID').format(num);
};

const formatDateFull = (date) => {
    try {
        return format(new Date(date), 'EEEE, d MMMM yyyy, HH:mm', { locale: id });
    } catch (e) {
        return date;
    }
};

const getDisplayNote = (item) => {
    if (!item.note) return '';
    let note = item.note;
    
    // Check if note starts with modifiers (approximate check generated by frontend)
    if (item.modifiers && item.modifiers.length) {
        const modString = item.modifiers.map(m => m.option_name).join(', ');
        // The generator usually adds ". " or similar. 
        // We simply check if the note starts with the modString.
        if (note.startsWith(modString)) {
            // Remove the modifier string
            note = note.substring(modString.length).trim();
            // Remove leading punctuation if any (like . or ,)
            if (note.startsWith('.') || note.startsWith(',')) {
                note = note.substring(1).trim();
            }
        }
    }
    return note;
};
</script>

<style>
@media print {
    /* Hide everything */
    body * {
        visibility: hidden;
    }

    /* Show Receipt specifically */
    #pos-receipt, #pos-receipt * {
        visibility: visible;
    }
    
    #pos-receipt {
        position: absolute;
        left: 0;
        top: 0;
        width: 100%;
        margin: 0;
        padding: 0; /* Remove padding for thermal alignment */
    }
    
    /* Ensure bold works well on thermal printers */
    .font-bold {
        font-weight: 900;
    }

    @page {
        margin: 0;
        size: auto;
    }
}
</style>
