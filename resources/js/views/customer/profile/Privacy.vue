<template>
    <MobileLayout :showHeader="false" :showFooter="false">
        <div class="min-h-screen bg-white">
            <!-- Header -->
            <div class="bg-white sticky top-0 z-10 px-4 py-3 flex items-center gap-3 border-b border-gray-100">
                <button @click="$router.back()" class="w-10 h-10 flex items-center justify-center rounded-full hover:bg-gray-100 transition-colors">
                    <ChevronLeftIcon class="w-6 h-6 text-gray-700" />
                </button>
                <h1 class="text-lg font-bold text-gray-900">Kebijakan Privasi</h1>
            </div>

            <div class="p-5 text-gray-600 text-sm leading-relaxed space-y-6">
                <div>
                     <p class="mb-2"><strong>Daftar Privasi Ruang Bincang Coffee</strong></p>
                     <p>Kami menghargai privasi Anda dan berkomitmen untuk melindungi data pribadi yang Anda bagikan kepada kami melalui aplikasi ini.</p>
                </div>

                <section>
                     <h3 class="font-bold text-gray-900 mb-2">1. Data yang Kami Kumpulkan</h3>
                     <p class="mb-2">Saat Anda mendaftar atau melakukan pemesanan, kami mungkin mengumpulkan data berikut:</p>
                     <ul class="list-disc pl-5 space-y-1">
                        <li>Nama Lengkap (untuk identifikasi pesanan).</li>
                        <li>Nomor Telepon / WhatsApp (untuk verifikasi login OTP dan notifikasi pesanan).</li>
                        <li>Tanggal Lahir (opsional, untuk promo ulang tahun).</li>
                     </ul>
                </section>

                <section>
                     <h3 class="font-bold text-gray-900 mb-2">2. Penggunaan Data</h3>
                     <p class="mb-2">Data Anda digunakan semata-mata untuk:</p>
                     <ul class="list-disc pl-5 space-y-1">
                        <li>Memproses dan mengkonfirmasi pesanan Anda.</li>
                        <li>Mengirimkan notifikasi status pesanan (Siap/Selesai).</li>
                        <li>Menghitung Poin Membership dan memberikan promo yang relevan.</li>
                        <li>Kami <strong>tidak pernah</strong> menjual atau membagikan data pribadi Anda kepada pihak ketiga manapun.</li>
                     </ul>
                </section>

                <section>
                     <h3 class="font-bold text-gray-900 mb-2">3. Keamanan Akun</h3>
                     <p>Kami menggunakan verifikasi OTP (One-Time Password) melalui WhatsApp untuk memastikan keamanan akses akun Anda. Jangan pernah memberikan kode OTP kepada siapapun, termasuk pihak yang mengaku dari Ruang Bincang Coffee.</p>
                </section>

                <section>
                     <h3 class="font-bold text-gray-900 mb-2">4. Hak Anda</h3>
                     <p>Anda berhak untuk mengubah informasi profil Anda atau meminta penghapusan akun kapan saja dengan menghubungi layanan pelanggan kami.</p>
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
