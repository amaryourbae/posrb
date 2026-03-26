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
        Schema::create('modifier_option_sale_prices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('modifier_option_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('sales_type_id')->constrained('sales_types')->cascadeOnDelete();
            $table->decimal('price', 12, 2);
            $table->timestamps();

            $table->unique(['modifier_option_id', 'sales_type_id'], 'mo_sales_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('modifier_option_sale_prices');
    }
};
