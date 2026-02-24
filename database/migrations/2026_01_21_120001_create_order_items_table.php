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
        Schema::create('order_items', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('order_id')->constrained('orders')->cascadeOnDelete();
            $table->foreignUlid('product_id')->constrained('products'); // History remains even if product deleted? No, keep it linkable. Logic handle softdelete.
            
            $table->integer('quantity');
            $table->decimal('unit_price', 12, 2); // Price at moment of purchase
            $table->decimal('unit_cost', 12, 2)->default(0); // Estimated HPP at moment of purchase
            $table->decimal('total_price', 12, 2); // qty * price
            $table->string('note')->nullable(); // "Less Sugar"
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_items');
    }
};
