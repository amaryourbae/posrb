<template>
<MobileLayout :showHeader="false" :showFooter="false">
    <div class="flex flex-col min-h-screen bg-white font-sans text-slate-900 pb-safe">
        <!-- Header -->
        <header class="sticky top-0 z-50 bg-white/95 backdrop-blur-sm px-5 py-4 flex items-center shadow-[0_1px_2px_rgba(0,0,0,0.03)] justify-between">
            <div class="flex items-center gap-3">
                <button @click="$router.go(-1)" class="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100 -ml-2 text-slate-900">
                    <ChevronLeftIcon class="w-6 h-6" />
                </button>
                <h1 class="text-xl font-bold tracking-tight text-slate-900">Pusat Bantuan</h1>
            </div>
        </header>

        <main class="flex-1 w-full overflow-y-auto no-scrollbar pt-6 px-5 pb-10 space-y-8">
            
            <!-- Contact Channels -->
             <section>
                <h2 class="text-lg font-bold text-slate-900 mb-4">Hubungi Kami</h2>
                <div class="grid grid-cols-2 gap-3">
                    <a href="https://wa.me/6281234567890" target="_blank" class="flex flex-col items-center gap-2 p-4 rounded-2xl bg-[#25D366]/10 border border-[#25D366]/20 active:scale-[0.98] transition-all">
                        <div class="w-10 h-10 rounded-full bg-[#25D366] text-white flex items-center justify-center">
                            <MessageCircleIcon class="w-5 h-5" />
                        </div>
                        <div class="text-center">
                            <p class="text-xs font-bold text-slate-900">WhatsApp</p>
                            <p class="text-[10px] text-slate-500">Respon Cepat</p>
                        </div>
                    </a>
                    
                    <a href="mailto:support@posrb.id" class="flex flex-col items-center gap-2 p-4 rounded-2xl bg-blue-50 border border-blue-100 active:scale-[0.98] transition-all">
                        <div class="w-10 h-10 rounded-full bg-blue-500 text-white flex items-center justify-center">
                            <MailIcon class="w-5 h-5" />
                        </div>
                        <div class="text-center">
                            <p class="text-xs font-bold text-slate-900">Email</p>
                            <p class="text-[10px] text-slate-500">1x24 Jam</p>
                        </div>
                    </a>
                </div>
            </section>

            <!-- FAQ Section -->
            <section>
                <h2 class="text-lg font-bold text-slate-900 mb-4">Pertanyaan Umum (FAQ)</h2>
                <div class="space-y-3">
                    <div 
                        v-for="(item, index) in faqItems" 
                        :key="index"
                        class="border border-gray-100 rounded-xl overflow-hidden bg-white shadow-sm transition-all duration-300"
                        :class="{'border-primary/30 ring-1 ring-primary/10': activeIndex === index}"
                    >
                        <button 
                            @click="toggle(index)"
                            class="w-full flex items-center justify-between p-4 bg-white text-left text-sm font-semibold text-slate-800"
                        >
                            <span>{{ item.question }}</span>
                            <ChevronDownIcon 
                                class="w-5 h-5 text-gray-400 transition-transform duration-300" 
                                :class="{'rotate-180 text-primary': activeIndex === index}"
                            />
                        </button>
                        <div 
                            v-show="activeIndex === index"
                            class="px-4 pb-4 text-sm text-slate-500 leading-relaxed bg-white border-t border-dashed border-gray-100 pt-3"
                        >
                            {{ item.answer }}
                        </div>
                    </div>
                </div>
            </section>

             <!-- Footer Note -->
             <div class="text-center pt-8 pb-4">
                <p class="text-xs text-gray-400">Jam Operasional CS: 09:00 - 21:00 WIB</p>
             </div>
        </main>
    </div>
</MobileLayout>
</template>

<script setup>
import { ref } from 'vue';
import MobileLayout from '../../layouts/MobileLayout.vue';
import { ChevronLeftIcon, ChevronDownIcon, MessageCircleIcon, MailIcon } from 'lucide-vue-next';

const activeIndex = ref(null);

const toggle = (index) => {
    activeIndex.value = activeIndex.value === index ? null : index;
};

const faqItems = [
    {
        question: "Bagaimana cara mendapatkan poin?",
        answer: "Poin didapatkan secara otomatis setiap kali Anda melakukan transaksi. Anda akan mendapatkan 2 Poin per transaksi tanpa minimum pembelian."
    },
    {
        question: "Berapa lama poin saya berlaku?",
        answer: "Poin loyalitas berlaku selama 1 tahun (365 hari) sejak tanggal didapatkan. Pastikan Anda menggunakannya sebelum kedaluwarsa."
    },
    {
        question: "Bagaimana cara menggunakan voucher?",
        answer: "Masuk ke menu 'Voucher' di halaman Profil atau saat Checkout. Pilih voucher yang tersedia dan klik 'Gunakan' untuk menerapkan diskon."
    },
    {
        question: "Apakah saya bisa mengubah pesanan?",
        answer: "Pesanan yang sudah dibayar dan diproses tidak dapat diubah secara mandiri melalui aplikasi. Silakan hubungi staff kasir atau CS kami untuk bantuan segera."
    },
    {
        question: "Metode pembayaran apa saja yang tersedia?",
        answer: "Kami menerima pembayaran Tunai/Kasir (Dine-in), QRIS (Semua E-Wallet & Mobile Banking), dan Kartu Debit/Kredit."
    }
];
</script>

<style scoped>
.pb-safe {
    padding-bottom: max(env(safe-area-inset-bottom), 1.5rem);
}
.no-scrollbar::-webkit-scrollbar {
    display: none;
}
.no-scrollbar {
    -ms-overflow-style: none;
    scrollbar-width: none;
}
</style>
