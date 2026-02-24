<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <!-- Backdrop -->
        <div class="fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity" @click.self="$emit('close')"></div>

        <!-- Modal Content -->
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-md lg:max-w-3xl relative z-10 flex flex-col max-h-[90vh]">
            
            <!-- Header -->
            <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
                <div>
                    <h3 class="font-bold text-lg text-gray-900">{{ product.name }}</h3>
                    <p class="text-sm text-gray-500">{{ formatCurrency(basePrice) }}</p>
                </div>
                <button @click="$emit('close')" class="p-2 hover:bg-gray-100 rounded-full transition text-gray-500">
                    <XIcon class="w-5 h-5" />
                </button>
            </div>

            <!-- Modifiers List -->
            <div class="flex-1 overflow-y-auto px-6 py-4 space-y-6">
                <div v-for="modifier in visibleModifiers" :key="modifier.id">
                    <div class="flex justify-between items-center mb-2">
                        <h4 class="font-bold text-gray-800 text-sm uppercase tracking-wide">
                            {{ modifier.name }}
                            <span v-if="modifier.is_required" class="text-red-500 ml-1 text-xs normal-case">(Required)</span>
                        </h4>
                        <!-- Show "Multiple" label only if type is NOT single/radio/select -->
                        <span v-if="!['single', 'radio', 'select'].includes(modifier.type)" class="text-xs text-gray-400">Optional, multiple</span>
                    </div>
                    
                    <div class="space-y-2">
                        <!-- Single Choice (Radio) -->
                        <div v-if="['single', 'radio', 'select'].includes(modifier.type)" class="grid grid-cols-1 lg:grid-cols-2 gap-3">
                            <label 
                                v-for="option in getFilteredOptions(modifier)" 
                                :key="option.id"
                                class="flex items-center justify-between p-3 rounded-xl border cursor-pointer hover:bg-gray-50 transition"
                                :class="selections[modifier.id] === option ? 'border-primary ring-1 ring-primary bg-primary/5' : 'border-gray-200'"
                            >
                                <div class="flex items-center gap-3">
                                    <div class="w-4 h-4 rounded-full border flex items-center justify-center shrink-0"
                                         :class="selections[modifier.id] === option ? 'border-primary' : 'border-gray-300'"
                                    >
                                        <div v-if="selections[modifier.id] === option" class="w-2 h-2 rounded-full bg-primary"></div>
                                    </div>
                                    <span class="font-medium text-sm text-gray-700">{{ option.name }}</span>
                                </div>
                                <span v-if="option.price > 0" class="text-sm font-semibold text-gray-900">+{{ formatCurrency(option.price) }}</span>
                                <input 
                                    type="radio" 
                                    :name="`mod-${modifier.id}`" 
                                    :value="option" 
                                    v-model="selections[modifier.id]"
                                    class="hidden"
                                />
                            </label>
                        </div>

                        <!-- Multiple Choice (Checkbox) -->
                        <div v-else class="grid grid-cols-1 lg:grid-cols-2 gap-3">
                             <label 
                                v-for="option in getFilteredOptions(modifier)" 
                                :key="option.id"
                                class="flex items-center justify-between p-3 rounded-xl border cursor-pointer hover:bg-gray-50 transition"
                                :class="isSelected(modifier.id, option) ? 'border-primary ring-1 ring-primary bg-primary/5' : 'border-gray-200'"
                            >
                                <div class="flex items-center gap-3">
                                    <div class="w-4 h-4 rounded border flex items-center justify-center shrink-0"
                                         :class="isSelected(modifier.id, option) ? 'bg-primary border-primary' : 'border-gray-300'"
                                    >
                                        <CheckIcon v-if="isSelected(modifier.id, option)" class="w-3 h-3 text-white" />
                                    </div>
                                    <span class="font-medium text-sm text-gray-700">{{ option.name }}</span>
                                </div>
                                <span v-if="option.price > 0" class="text-sm font-semibold text-gray-900">+{{ formatCurrency(option.price) }}</span>
                                <input 
                                    type="checkbox" 
                                    :value="option" 
                                    @change="toggleSelection(modifier.id, option)"
                                    class="hidden"
                                />
                            </label>
                        </div>
                    </div>
                </div>

                <!-- Note -->
                 <div>
                    <label class="font-bold text-gray-800 text-sm uppercase tracking-wide mb-2 block">Note</label>
                    <textarea 
                        v-model="note"
                        class="w-full p-3 border border-gray-200 rounded-xl text-sm focus:ring-1 focus:ring-primary focus:border-primary outline-none"
                        rows="2"
                        placeholder="Add special instructions..."
                    ></textarea>
                </div>
            </div>

            <!-- Footer -->
            <div class="p-6 border-t border-gray-100 bg-gray-50 rounded-b-2xl">
                <button 
                    @click="confirmSelection"
                    :disabled="!isValid"
                    class="w-full bg-primary hover:bg-[#004d34] text-white font-bold py-3.5 rounded-xl shadow-lg shadow-primary/20 transition transform active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed flex justify-between px-6"
                >
                    <span>Add to Order</span>
                    <span>{{ formatCurrency(totalPrice) }}</span>
                </button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import { XIcon, CheckIcon } from 'lucide-vue-next';
import { formatCurrency } from '../../utils/format';

const props = defineProps({
    isOpen: Boolean,
    product: {
        type: Object,
        required: true
    },
    initialSelections: {
        type: Object,
        default: () => ({})
    },
    initialNote: {
        type: String,
        default: ''
    }
});

const emit = defineEmits(['close', 'confirm']);

const selections = ref({}); // { modId: optionObj (single) or [optionObj] (multiple) }
const note = ref('');

// Reset selections when modal opens for a new product
watch(() => props.product, (newVal) => {
    if (newVal) {
        // If initialSelections provided (editing mode), load them
        if (props.isOpen && Object.keys(props.initialSelections).length > 0) {
             // Deep copy to avoid reference issues
             selections.value = JSON.parse(JSON.stringify(props.initialSelections));
             note.value = props.initialNote;
        } else {
            // New item mode
            selections.value = {};
            note.value = '';
            // Pre-select defaults if needed (e.g. first option for required single choice)
            newVal.modifiers?.forEach(mod => {
                if (mod.type === 'single' && mod.is_required && mod.options.length > 0) {
                     selections.value[mod.id] = mod.options[0];
                } else if (mod.type === 'multiple') {
                    selections.value[mod.id] = [];
                }
            });
        }
    }
}, { immediate: true });

// Also watch isOpen to re-initialize if product didn't change but modal re-opened
watch(() => props.isOpen, (isOpen) => {
    if (isOpen) {
         if (Object.keys(props.initialSelections).length > 0) {
             selections.value = JSON.parse(JSON.stringify(props.initialSelections));
             note.value = props.initialNote;
         } else if (Object.keys(selections.value).length === 0) {
            // Re-apply defaults if empty
             props.product?.modifiers?.forEach(mod => {
                if (mod.type === 'single' && mod.is_required && mod.options.length > 0) {
                     selections.value[mod.id] = mod.options[0];
                } else if (mod.type === 'multiple') {
                    selections.value[mod.id] = [];
                }
            });
         }
    }
});

const getFilteredOptions = (modifier) => {
    if (!modifier.pivot || !modifier.pivot.allowed_options) return modifier.options;
    
    try {
        let allowed = modifier.pivot.allowed_options;
        if (typeof allowed === 'string') {
            allowed = JSON.parse(allowed);
        }
        
        // If it's a non-empty array, filter
        if (Array.isArray(allowed) && allowed.length > 0) {
            // Check if contents are numbers/strings (IDs) or objects
            const first = allowed[0];
            if (typeof first === 'object') {
                 // If objects, extract IDs
                 const allowedIds = allowed.map(a => a.id);
                 return modifier.options.filter(opt => allowedIds.includes(opt.id));
            } else {
                 // Assume IDs
                 // Ensure types match (string vs int)
                 return modifier.options.filter(opt => allowed.some(aId => aId == opt.id));
            }
        }
    } catch (e) {
        console.error('Error parsing allowed_options', e);
    }
    
    return modifier.options;
};

const basePrice = computed(() => parseFloat(props.product.price) || 0);

const totalPrice = computed(() => {
    let total = basePrice.value;
    for (const modId in selections.value) {
        const selection = selections.value[modId];
        if (Array.isArray(selection)) {
             selection.forEach(opt => total += parseFloat(opt.price) || 0);
        } else if (selection) {
             total += parseFloat(selection.price) || 0;
        }
    }
    return total;
});

const isSelected = (modId, option) => {
    const list = selections.value[modId];
    return Array.isArray(list) && list.some(o => o.id === option.id);
};

const toggleSelection = (modId, option) => {
    let list = selections.value[modId] || [];
    const index = list.findIndex(o => o.id === option.id);
    if (index === -1) {
        list.push(option);
    } else {
        list.splice(index, 1);
    }
    selections.value[modId] = list; // Trigger reactivity
};

const visibleModifiers = computed(() => {
    if (!props.product || !props.product.modifiers) return [];

    // Check if 'Iced' is selected in any modifier (usually in 'Available')
    let isIcedSelected = false;
    for (const modId in selections.value) {
        const val = selections.value[modId];
        if (Array.isArray(val)) {
             if (val.some(o => o.name === 'Iced')) isIcedSelected = true;
        } else if (val) {
             if (val.name === 'Iced') isIcedSelected = true;
        }
    }

    const filtered = props.product.modifiers.filter(mod => {
        // Condition: 'Ice Cube' only visible if 'Iced' is selected
        if (mod.name === 'Ice Cube') {
            return isIcedSelected;
        }
        return true;
    });

    // Custom Sort: "Available" first, then "Size", then others based on Sort Order
    return filtered.sort((a, b) => {
        const priority = { 'Available': 0, 'Size': 1 };
        
        // Get priority, default to 2 (after Available and Size)
        const pA = priority[a.name] !== undefined ? priority[a.name] : 2;
        const pB = priority[b.name] !== undefined ? priority[b.name] : 2;
        
        if (pA !== pB) return pA - pB;
        
        // Fallback to existing sort order (pivot or id)
        return (a.pivot?.sort_order || 0) - (b.pivot?.sort_order || 0);
    });
});

const isValid = computed(() => {
    // Validate only visible modifiers to prevent validation blocking on hidden required fields
    if (!visibleModifiers.value) return true;
    return visibleModifiers.value.every(mod => {
        if (mod.is_required && mod.type === 'single') {
            return !!selections.value[mod.id];
        }
        return true;
    });
});

const confirmSelection = () => {
    if (!isValid.value) return;

    // Flatten selections into array of options
    let allModifiers = [];
    for (const modId in selections.value) {
        const val = selections.value[modId];
        const originalMod = props.product.modifiers.find(m => m.id == modId);
        
        const attachDefaultFlag = (optionObj) => {
             if (!originalMod || !originalMod.options || originalMod.options.length === 0) return false;
             return originalMod.options[0].id === optionObj.id;
        };

        if (Array.isArray(val)) {
            val.forEach(v => allModifiers.push({
                ...v, 
                modifier_id: modId, 
                option_id: v.id, 
                option_name: v.name,
                modifier_name: originalMod ? originalMod.name : '',
                is_default: attachDefaultFlag(v)
            }));
        } else if (val) {
            allModifiers.push({
                ...val, 
                modifier_id: modId, 
                option_id: val.id, 
                option_name: val.name,
                modifier_name: originalMod ? originalMod.name : '',
                is_default: attachDefaultFlag(val)
            });
        }
    }

    emit('confirm', {
        product: props.product,
        modifiers: allModifiers,
        note: note.value
    });
    emit('close');
};
</script>
