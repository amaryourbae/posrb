<template>
    <MobileLayout :showHeader="false" :showFooter="false">
        <div class="min-h-screen bg-white">
            <!-- Header -->
            <div class="bg-white sticky top-0 z-10 px-4 py-3 flex items-center gap-3 border-b border-gray-100">
                <button @click="$router.back()" class="w-10 h-10 flex items-center justify-center rounded-full hover:bg-gray-100 transition-colors">
                    <ChevronLeftIcon class="w-6 h-6 text-gray-700" />
                </button>
                <h1 class="text-lg font-bold text-gray-900">Syarat & Ketentuan</h1>
            </div>

            <div class="p-5 text-gray-600 text-sm leading-relaxed space-y-6">
                <div>
                     <p class="mb-2">Selamat datang di Aplikasi <strong>Ruang Bincang Coffee</strong>.</p>
                     <p>Aplikasi ini dikelola oleh Ruang Bincang Coffee untuk memudahkan pelanggan dalam melakukan pemesanan (Pickup & Dine In) serta mengelola keanggotaan (Membership).</p>
                </div>

                <section>
                     <h3 class="font-bold text-gray-900 mb-2">1. Penggunaan Aplikasi</h3>
                     <ul class="list-disc pl-5 space-y-1">
                        <li>Aplikasi ini dapat digunakan oleh semua pelanggan untuk melihat menu, promo, dan melakukan pemesanan.</li>
                        <li>Pendaftaran akun diperlukan untuk mengakses fitur Membership, mengumpulkan Poin, dan menukarkan Voucher.</li>
                     </ul>
                </section>

                <section>
                     <h3 class="font-bold text-gray-900 mb-2">2. Pemesanan (Pickup & Dine In)</h3>
                     <ul class="list-disc pl-5 space-y-1">
                        <li><strong>Pickup:</strong> Pelanggan wajib mengambil pesanan sesuai estimasi waktu yang diberikan. Keterlambatan pengambilan yang menyebabkan penurunan kualitas produk (misal: es mencair) bukan tanggung jawab kami.</li>
                        <li><strong>Dine In:</strong> Pastikan Anda sudah mendapatkan meja atau berada di lokasi saat melakukan pemesanan Dine In.</li>
                        <li>Pesanan yang sudah dikonfirmasi dan dibayar tidak dapat dibatalkan.</li>
                     </ul>
                </section>

                <section>
                     <h3 class="font-bold text-gray-900 mb-2">3. Keanggotaan & Poin</h3>
                     <ul class="list-disc pl-5 space-y-1">
                        <li>Setiap transaksi senilai Rp 10.000 akan mendapatkan 1 Poin (berlaku kelipatan).</li>
                        <li>Poin tidak dapat diuangkan namun dapat ditukar dengan Voucher Potongan Harga atau Produk Gratis.</li>
                        <li>Ruang Bincang Coffee berhak membatalkan poin jika ditemukan indikasi kecurangan.</li>
                     </ul>
                </section>

                <section>
                     <h3 class="font-bold text-gray-900 mb-2">4. Pembayaran</h3>
                     <p>Kami menerima pembayaran melalui QRIS dan Metode Cashless lainnya yang tersedia di aplikasi. Pastikan melakukan pembayaran sesuai nominal yang tertera.</p>
                </section>

                <p class="pt-4 text-xs text-gray-400 border-t border-gray-100 mt-4">Terakhir diperbarui: 25 Januari 2026</p>
            </div>
        </div>
    </MobileLayout>
</template>

<script setup>
import { ChevronLeftIcon } from 'lucide-vue-next';
import MobileLayout from '../../../layouts/MobileLayout.vue';
</script>
