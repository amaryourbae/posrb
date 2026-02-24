export function useProductDisplay() {
    
    // Check if a modifier is the special "Available" (Iced/Hot) modifier
    const isAvailableModifier = (modName) => {
        return modName === 'Available';
    };

    // Check if a modifier is the "Size" modifier
    const isSizeModifier = (modName) => {
        return modName === 'Size';
    };

    // Get the formatted product name (e.g. "Reguler Iced Americano")
    const getProductName = (item) => {
        if (!item) return '';
        let name = item.product_name || item.name;
        
        if (item.modifiers && item.modifiers.length > 0) {
            // Find "Available" modifier (Iced/Hot) - prepend first (inner)
            const availableMod = item.modifiers.find(m => isAvailableModifier(m.modifier_name || m.name));
            if (availableMod) {
                const optName = availableMod.option_name || availableMod.name;
                if (optName && !name.toLowerCase().includes(optName.toLowerCase())) {
                    name = `${optName} ${name}`;
                }
            }
            
            // Find "Size" modifier (Reguler/Large) - prepend second (outer)
            const sizeMod = item.modifiers.find(m => isSizeModifier(m.modifier_name || m.name));
            if (sizeMod) {
                const optName = sizeMod.option_name || sizeMod.name;
                if (optName && !name.toLowerCase().includes(optName.toLowerCase())) {
                    name = `${optName} ${name}`;
                }
            }
        }
        return name;
    };

    // Get modifiers list - now returns all except Size and Available
    const getVisibleModifiers = (item) => {
        if (!item || !item.modifiers) return [];
        return item.modifiers.filter(m => {
            const name = m.modifier_name || m.name;
            // Hide Size and Available modifiers (already in product name)
            if (isSizeModifier(name) || isAvailableModifier(name)) return false;
            return true;
        });
    };

    // Get display name for modifier: "Normal" + "Ice Cube" → "Normal Ice"
    const getModifierDisplayName = (mod) => {
        if (!mod) return '';
        const optName = mod.option_name || mod.name || '';
        const modName = mod.modifier_name || mod.name || '';
        
        // Skip if either is missing
        if (!optName || !modName) return optName;
        
        // Skip for Size/Available specifically in this display logic just in case
        if (isSizeModifier(modName) || isAvailableModifier(modName)) return optName;
        
        // Handle Ice Cube case specifically as requested
        if (modName.toLowerCase().includes('ice')) {
            // Normal Ice, Less Ice, Extra Ice
            if (['Normal', 'Less', 'Extra'].includes(optName)) {
                return `${optName} Ice`;
            }
        }
        
        // Check if option already contains part of modifier
        const modWords = modName.split(' ');
        for (const word of modWords) {
            if (word.length > 2 && optName.toLowerCase().includes(word.toLowerCase())) {
                return optName;
            }
        }
        
        // Combine: "Normal" + "Ice Cube" → "Normal Ice"
        return `${optName} ${modWords[0]}`;
    };

    return {
        getProductName,
        getVisibleModifiers,
        getModifierDisplayName
    };
}
