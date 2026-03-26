<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use App\Models\Unit;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // First, add the new column nullable to avoid issues
        if (!Schema::hasColumn('ingredients', 'unit_id')) {
            Schema::table('ingredients', function (Blueprint $table) {
                $table->foreignId('unit_id')->nullable()->constrained('units')->onDelete('restrict');
            });
        }

        // Migrate existing data
        if (Schema::hasColumn('ingredients', 'unit')) {
            $ingredients = DB::table('ingredients')->get();
            foreach ($ingredients as $ingredient) {
                $unitName = ucfirst($ingredient->unit);
                if ($ingredient->unit === 'pcs') {
                    $unitName = 'Pieces';
                } elseif ($ingredient->unit === 'ml') {
                    $unitName = 'Milliliter';
                }
                
                $unit = Unit::firstOrCreate(
                    ['abbreviation' => strtolower($ingredient->unit)],
                    ['name' => $unitName]
                );

                DB::table('ingredients')
                    ->where('id', $ingredient->id)
                    ->update(['unit_id' => $unit->id]);
            }
        }

        // Now make it not nullable and drop the old column
        Schema::table('ingredients', function (Blueprint $table) {
            $table->foreignId('unit_id')->nullable(false)->change();
        });

        if (Schema::hasColumn('ingredients', 'unit')) {
            Schema::table('ingredients', function (Blueprint $table) {
                $table->dropColumn('unit');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (!Schema::hasColumn('ingredients', 'unit')) {
            Schema::table('ingredients', function (Blueprint $table) {
                // Add the old column back
                $table->string('unit')->default('gram');
            });
        }

        // Try to reverse migrate data
        if (Schema::hasColumn('ingredients', 'unit_id')) {
            $ingredients = DB::table('ingredients')->join('units', 'ingredients.unit_id', '=', 'units.id')->get();
            foreach ($ingredients as $ingredient) {
                 DB::table('ingredients')
                    ->where('id', $ingredient->id)
                    ->update(['unit' => $ingredient->abbreviation]);
            }

            Schema::table('ingredients', function (Blueprint $table) {
                 $table->dropForeign(['unit_id']);
                 $table->dropColumn('unit_id');
            });
        }
    }
};
