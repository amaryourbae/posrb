<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('order_payments', function (Blueprint $table) {
            $table->id();
            $table->foreignUlid('order_id')->constrained()->cascadeOnDelete();
            $table->string('payment_method');
            $table->decimal('amount', 15, 2);
            $table->string('status')->default('paid'); // pending, paid, refunded, failed
            $table->string('reference_id')->nullable(); // For EDC or QRIS ref
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_payments');
    }
};
