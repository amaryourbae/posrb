<template>
    <Teleport to="body">
        <Transition name="fade">
            <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center">
                <div class="absolute inset-0 bg-black/50" @click="$emit('close')"></div>
                
                <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-sm mx-4 overflow-hidden">
                    <div class="p-6">
                        <div class="text-center mb-6">
                            <div class="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-4">
                                <ShieldCheckIcon class="w-8 h-8 text-orange-600" />
                            </div>
                            <h2 class="text-xl font-bold text-gray-900">Manager Authorization</h2>
                            <p class="text-sm text-gray-500 mt-1">{{ message || 'Enter manager PIN to continue' }}</p>
                        </div>
                        
                        <div class="mb-6">
                            <label class="block text-xs font-bold text-gray-500 uppercase mb-2">Manager PIN</label>
                            <input 
                                ref="pinInput"
                                v-model="pin"
                                type="password"
                                maxlength="6"
                                class="w-full px-4 py-3 text-center text-2xl font-bold tracking-widest border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary focus:border-primary outline-none"
                                placeholder="••••••"
                                @keyup.enter="submit"
                            />
                            <p v-if="error" class="text-red-500 text-sm text-center mt-2">{{ error }}</p>
                        </div>
                        
                        <div class="flex gap-3">
                            <button 
                                @click="$emit('close')"
                                class="flex-1 px-4 py-3 bg-gray-100 text-gray-700 font-bold rounded-xl hover:bg-gray-200 transition"
                            >
                                Cancel
                            </button>
                            <button 
                                @click="submit"
                                :disabled="pin.length < 4 || loading"
                                class="flex-1 px-4 py-3 bg-primary text-white font-bold rounded-xl hover:bg-[#004d34] transition disabled:opacity-50"
                            >
                                <LoaderIcon v-if="loading" class="w-5 h-5 animate-spin mx-auto" />
                                <span v-else>Confirm</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </Transition>
    </Teleport>
</template>

<script setup>
import { ref, watch, nextTick } from 'vue';
import { ShieldCheckIcon, LoaderIcon } from 'lucide-vue-next';

const props = defineProps({
    isOpen: Boolean,
    message: String,
    loading: Boolean,
    error: String
});

const emit = defineEmits(['close', 'submit']);

const pin = ref('');
const pinInput = ref(null);

const submit = () => {
    if (pin.value.length >= 4) {
        emit('submit', pin.value);
    }
};

watch(() => props.isOpen, async (val) => {
    if (val) {
        pin.value = '';
        await nextTick();
        pinInput.value?.focus();
    }
});
</script>

<style scoped>
.fade-enter-active, .fade-leave-active { transition: opacity 0.2s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
