<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 flex items-end sm:items-center justify-center sm:p-4">
        <!-- Backdrop -->
        <div class="fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity" @click="$emit('continue')"></div>

        <!-- Modal Content -->
        <div class="bg-white w-full max-w-md rounded-t-3xl sm:rounded-3xl shadow-2xl relative z-10 flex flex-col max-h-[90vh] animate-in slide-in-from-bottom-10 fade-in duration-300">
            
            <!-- Handle bar for mobile -->
            <div class="w-full flex justify-center pt-3 pb-1 sm:hidden">
                <div class="w-12 h-1.5 bg-gray-300 rounded-full"></div>
            </div>

            <!-- Header -->
            <div class="p-5 text-center">
                <h3 class="font-bold text-xl text-primary">Lengkapi Belanjamu</h3>
            </div>

            <!-- Success Card -->
            <div class="px-5">
                <div class="flex gap-4 p-4 rounded-2xl border border-gray-100 shadow-sm bg-white items-center relative overflow-hidden">
                    <!-- Green success strip at bottom?? No, from image looks like standard card -->
                    <!-- But there is text "Berhasil masuk ke keranjang!" in green below details -->
                    
                    <div class="w-20 h-20 rounded-xl bg-gray-100 overflow-hidden shrink-0">
                        <img :src="item?.image_url || '/no-image.jpg'" class="w-full h-full object-cover" />
                    </div>
                    
                    <div class="flex-1 min-w-0">
                        <div class="flex justify-between items-start">
                             <h4 class="font-bold text-gray-900 line-clamp-2 leading-tight">{{ getProductName(item) }}</h4>
                             <span class="w-7 h-7 flex items-center justify-center rounded-full bg-gray-100 text-xs font-bold text-gray-600 shrink-0 ml-2">
                                {{ item?.quantity || 1 }}
                             </span>
                        </div>
                        <p class="text-xs text-gray-500 mt-1 line-clamp-1">
                             {{ getVisibleModifiers(item).map(m => m.option_name).join(', ') }}
                             <span v-if="!item?.modifiers?.length && !getVisibleModifiers(item).length">Regular</span>
                        </p>
                        <p class="text-xs font-bold text-green-600 mt-2 flex items-center gap-1">
                            Berhasil masuk ke keranjang!
                        </p>
                    </div>
                </div>
            </div>

            <!-- Upsell Section -->
            <div class="px-5 py-6">
                <div class="flex items-center gap-2 mb-3">
                    <div class="w-5 h-5 rounded-full bg-orange-100 flex items-center justify-center">
                         <ThumbsUpIcon class="w-3 h-3 text-orange-500" />
                    </div>
                    <p class="text-sm font-bold text-gray-800">Ssst.. tambah ini jadi lebih enak lho!</p>
                </div>

                <!-- Horizontal Scrollable Chips -->
                <div class="flex gap-2 overflow-x-auto no-scrollbar pb-2 -mx-5 px-5">
                    <!-- Mock Upsells or Filtered Modifiers -->
                    <!-- We can create dummy upsells if we don't have real logic yet -->
                     <button 
                        v-for="(suggestion, idx) in suggestions" 
                        :key="idx"
                        @click="addSuggestion(suggestion)"
                        class="shrink-0 px-4 py-2 rounded-full border border-gray-200 text-xs font-bold text-gray-600 hover:border-primary hover:text-primary hover:bg-primary/5 transition active:scale-95 whitespace-nowrap"
                    >
                        {{ suggestion.label }}
                        <span v-if="suggestion.displayPrice" class="ml-1 opacity-80 font-normal">{{ suggestion.displayPrice }}</span>
                    </button>
                </div>
            </div>

            <!-- Footer Buttons -->
            <div class="p-5 border-t border-gray-50 bg-gray-50/50 rounded-b-3xl space-y-3">
                <button 
                    @click="$emit('view-cart')"
                    class="w-full bg-primary hover:bg-[#4a5c2e] text-white font-bold py-3.5 rounded-full shadow-lg shadow-green-900/20 active:scale-[0.98] transition-all"
                >
                    Cek Keranjang
                </button>
                <button 
                    @click="$emit('continue')"
                    class="w-full bg-white border border-primary text-primary font-bold py-3.5 rounded-full hover:bg-green-50 active:scale-[0.98] transition-all"
                >
                    Lanjut Belanja
                </button>
            </div>

        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { ThumbsUpIcon } from 'lucide-vue-next';
import { useProductDisplay } from '../../composables/useProductDisplay';
import { formatCurrency } from '../../utils/format';

const props = defineProps({
    isOpen: Boolean,
    item: Object,
    product: Object // The full product object to find modifiers
});

const emit = defineEmits(['continue', 'view-cart', 'update-item']);

const { getProductName, getVisibleModifiers } = useProductDisplay();

// Filter suggestions based on unselected optional modifiers/upgrades
const suggestions = computed(() => {
    if (!props.product || !props.product.modifiers) return [];
    
    const selectedOptionIds = new Set();
    if (props.item && props.item.modifiers) {
        props.item.modifiers.forEach(m => selectedOptionIds.add(m.option_id));
    }
    
    let options = [];
    
    props.product.modifiers.forEach(mod => {
        // 1. Checkbox Modifiers (Add-ons)
        if (mod.type === 'checkbox') {
             mod.options.forEach(opt => {
                 if (!selectedOptionIds.has(opt.id)) {
                     options.push({
                         ...opt,
                         modifier_id: mod.id,
                         label: opt.name,
                         price: parseFloat(opt.price),
                         displayPrice: parseFloat(opt.price) > 0 ? `+${formatCurrency(opt.price)}` : ''
                     });
                 }
             });
        }
        // 2. Radio Modifiers (Upgrades) - Suggest higher value alternatives
        else if (mod.type === 'radio') {
             mod.options.forEach(opt => {
                 // Only suggest if it has a price > 0 (Upsell) and is not currently selected
                 if (!selectedOptionIds.has(opt.id) && parseFloat(opt.price) > 0) {
                      options.push({
                         ...opt,
                         modifier_id: mod.id,
                         label: opt.name,
                         price: parseFloat(opt.price),
                         displayPrice: `+${formatCurrency(opt.price)}`
                     });
                 }
             });
        }
    });

    return options;
});

const addSuggestion = (suggestion) => {
    // Emit update event to parent to handle the logic
    // We pass the full suggestion object which includes modifier_id and option details
    emit('update-item', suggestion);
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
</style>
