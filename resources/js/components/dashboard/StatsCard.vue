<template>
    <div
        class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow duration-300"
    >
        <div class="flex justify-between items-start mb-4">
            <div class="min-w-0 pr-2">
                <div class="text-sm text-gray-500 font-medium mb-1 truncate">
                    {{ title }}
                </div>
                <div 
                    class="font-bold text-slate-800 break-all"
                    :class="valueClass || 'text-2xl lg:text-3xl'"
                >
                    {{ value }}
                </div>
            </div>
            <div :class="`p-3 rounded-xl shrink-0 ${iconBgClass || 'bg-primary/5'}`">
                <component
                    :is="icon"
                    class="w-6 h-6"
                    :class="iconColorClass || 'text-primary'"
                />
            </div>
        </div>

        <div class="flex items-center text-xs">
            <span
                v-if="trend"
                :class="
                    trend > 0
                        ? 'text-green-500 bg-green-50'
                        : 'text-red-500 bg-red-50'
                "
                class="px-2 py-1 rounded-md font-bold flex items-center mr-2"
            >
                <ArrowUpIcon v-if="trend > 0" class="w-3 h-3 mr-1" />
                <ArrowDownIcon v-else class="w-3 h-3 mr-1" />
                {{ Math.abs(trend) }}%
            </span>
            <span class="text-gray-400">from last month</span>
        </div>
    </div>
</template>

<script setup>
import { ArrowUpIcon, ArrowDownIcon } from "lucide-vue-next";

defineProps({
    title: String,
    value: [String, Number],
    icon: [Object, Function],
    trend: Number,
    iconBgClass: String, 
    iconColorClass: String, 
    valueClass: String,
});
</script>
