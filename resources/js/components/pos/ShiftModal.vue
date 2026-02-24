<template>
    <div
        v-if="isOpen"
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
    >
        <!-- Backdrop -->
        <div
            class="absolute inset-0 bg-black/50 backdrop-blur-sm"
            @click="!isForce ? $emit('close') : null"
        ></div>

        <!-- Modal -->
        <div
            class="bg-white rounded-2xl shadow-xl w-full max-w-md relative z-10 overflow-hidden"
        >
            <!-- Header -->
            <div
                class="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50"
            >
                <h3 class="text-lg font-bold text-gray-900">
                    {{ mode === "start" ? "Start Shift" : "End Shift" }}
                </h3>
                <button
                    v-if="!isForce"
                    @click="$emit('close')"
                    class="p-1 rounded-full hover:bg-gray-200 text-gray-500"
                >
                    <XIcon class="w-5 h-5" />
                </button>
            </div>

            <!-- Body -->
            <div class="p-6 space-y-4">
                <div v-if="mode === 'start'">
                    <p class="text-sm text-gray-500 mb-4">
                        Please input the initial cash amount in the drawer to
                        start your shift.
                    </p>

                    <div>
                        <label
                            class="block text-sm font-medium text-gray-700 mb-1"
                            >Starting Cash</label
                        >
                        <div class="relative">
                            <span
                                class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 font-bold"
                                >Rp</span
                            >
                            <input
                                v-model="displayAmount"
                                @input="handleInput"
                                type="text"
                                class="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none font-bold text-lg"
                                placeholder="0"
                                autofocus
                            />
                        </div>
                    </div>
                </div>

                <div v-else>
                    <p class="text-sm text-gray-500 mb-4">
                        You are about to close your shift. Please verify the
                        cash amount.
                    </p>

                    <div
                        v-if="expectedCash !== null"
                        class="bg-blue-50 p-3 rounded-xl mb-4 text-sm"
                    >
                        <span class="text-blue-600 font-medium"
                            >Expected Cash:
                        </span>
                        <span class="font-bold text-blue-800">{{
                            formatCurrency(expectedCash)
                        }}</span>
                    </div>

                    <div class="space-y-3">
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 mb-1"
                                >Actual Cash Amount</label
                            >
                            <div class="relative">
                                <span
                                    class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 font-bold"
                                    >Rp</span
                                >
                                <input
                                    v-model="displayAmount"
                                    @input="handleInput"
                                    type="text"
                                    class="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none font-bold text-lg"
                                    placeholder="0"
                                />
                            </div>
                        </div>
                        <div>
                            <label
                                class="block text-sm font-medium text-gray-700 mb-1"
                                >Note (Optional)</label
                            >
                            <textarea
                                v-model="note"
                                rows="2"
                                class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none text-sm"
                                placeholder="Any discrepancies or notes..."
                            ></textarea>
                        </div>
                    </div>
                </div>

                <!-- Error -->
                <div
                    v-if="error"
                    class="text-red-500 text-sm bg-red-50 p-3 rounded-lg flex items-center gap-2"
                >
                    <AlertCircleIcon class="w-4 h-4" />
                    {{ error }}
                </div>
            </div>

            <!-- Footer -->
            <div
                class="px-6 py-4 border-t border-gray-100 bg-gray-50 flex justify-end gap-3"
            >
                <button
                    v-if="!isForce"
                    @click="$emit('close')"
                    class="px-5 py-2.5 rounded-xl font-medium text-gray-600 hover:bg-gray-200 transition"
                >
                    Cancel
                </button>
                <button
                    @click="submit"
                    class="px-5 py-2.5 rounded-xl font-bold text-white bg-primary hover:bg-[#004d34] shadow-lg shadow-primary/30 transition flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                    :disabled="loading || !amount"
                >
                    <LoaderIcon v-if="loading" class="w-4 h-4 animate-spin" />
                    {{ mode === "start" ? "Open Shift" : "End Shift" }}
                </button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, watch } from "vue";
import { XIcon, AlertCircleIcon, LoaderIcon } from "lucide-vue-next";
import { formatCurrency } from "../../utils/format";

const props = defineProps({
    isOpen: Boolean,
    mode: {
        type: String,
        default: "start", // 'start' or 'end'
    },
    isForce: {
        type: Boolean,
        default: false,
    },
    loading: Boolean,
    expectedCash: {
        type: Number,
        default: null,
    },
});

const emit = defineEmits(["close", "submit"]);

const amount = ref(0); // Store raw number
const displayAmount = ref(""); // Store formatted string for input
const note = ref("");
const error = ref(null);

watch(
    () => props.isOpen,
    (newVal) => {
        if (newVal) {
            amount.value = 0;
            displayAmount.value = "";
            note.value = "";
            error.value = null;
        }
    },
);

// Format input as Rupiah (with thousands separators)
const handleInput = (event) => {
    // 1. Get raw input
    let value = event.target.value;

    // 2. Remove all non-numeric characters
    const numericValue = value.replace(/\D/g, "");

    if (!numericValue) {
        amount.value = 0;
        displayAmount.value = "";
        return;
    }

    // 3. Convert to number
    const rawNumber = parseInt(numericValue, 10);
    amount.value = rawNumber;

    // 4. Format back to string with dots (IDN)
    // Note: We don't use decimals for Rupiah in this context usually, assuming full amounts
    const formatted = new Intl.NumberFormat("id-ID").format(rawNumber);

    displayAmount.value = formatted;
};

const submit = () => {
    if (amount.value <= 0 && amount.value !== 0) {
        // Allow 0? Assuming cash can be 0. But valid check.
        error.value = "Amount is required";
        return;
    }

    emit("submit", {
        amount: amount.value,
        note: note.value,
    });
};
</script>
