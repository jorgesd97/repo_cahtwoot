<template>
  <div class="w-full">
    <!-- TOOLBAR -->
    <div class="p-4 flex justify-between items-center border-b border-[#2A2E33] bg-[#151718]">
      <div class="relative w-64">
        <span class="absolute left-3 top-2.5 text-gray-500 text-sm">🔍</span>
        <input 
          type="text" 
          placeholder="Buscar producto..." 
          class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-1.5 pl-9 pr-3 text-sm focus:outline-none focus:border-teal-500 transition"
          v-model="searchQuery"
          @input="debounceSearch"
        >
      </div>
      <div class="flex items-center gap-3">
        <button class="bg-[#212529] text-gray-300 px-4 py-2 rounded text-sm border border-[#2A2E33] hover:border-gray-500 transition flex items-center">
          <span class="mr-2">📄</span> Importar Excel
        </button>
        <button 
          @click="openProductModal()"
          class="bg-teal-600 text-white px-4 py-2 rounded text-sm hover:bg-teal-700 font-medium transition flex items-center"
        >
          <span class="mr-2">+</span> Nuevo Producto
        </button>
      </div>
    </div>

    <!-- TABLA -->
    <div class="bg-[#151718] rounded-b border-x border-b border-[#2A2E33] overflow-hidden">
      <table class="w-full text-left text-sm text-gray-300">
        <thead class="bg-[#151718] border-b border-[#2A2E33] text-xs text-gray-500 uppercase tracking-wide">
          <tr>
            <th class="px-5 py-4 font-medium">Producto</th>
            <th class="px-5 py-4 font-medium">Tipo</th>
            <th class="px-5 py-4 font-medium w-24">Stock</th>
            <th class="px-5 py-4 font-medium w-28">Costo (S/)</th>
            <th class="px-5 py-4 font-medium w-28">Precio (S/)</th>
            <th class="px-5 py-4 font-medium">Margen</th>
            <th class="px-5 py-4 font-medium text-right">Acciones</th>
          </tr>
        </thead>
        <tbody>
          <!-- Tu v-for actual de productos -->
          <tr v-for="product in filteredProducts" :key="product.id" class="border-b border-[#2A2E33] hover:bg-[#1C1F21] transition">
            <td class="px-5 py-4 flex items-center space-x-3">
              <img :src="product.image_url" class="w-8 h-8 rounded border border-[#2A2E33]">
              <div class="font-medium text-gray-200">{{ product.title }}</div>
            </td>
            <td class="px-5 py-4 text-xs text-gray-400">{{ product.product_type }}</td>
            <td class="px-5 py-4">
              <span v-if="product.stock < 10" class="text-red-400 font-bold">{{ product.stock }}</span>
              <span v-else>{{ product.stock }}</span>
              <span v-if="product.stock < 10" class="text-red-400 text-xs"> (Bajo)</span>
            </td>
            <td class="px-5 py-4">S/ {{ parseFloat(product.cost || 0).toFixed(2) }}</td>
            <td class="px-5 py-4">S/ {{ parseFloat(product.price || 0).toFixed(2) }}</td>
            <td class="px-5 py-4">
              <span class="text-green-400 text-sm font-semibold">{{ calculateMargin(product) }}%</span>
            </td>
            <td class="px-5 py-4 text-right">
              <div class="flex items-center justify-end gap-2">
                <button 
                  @click="openProductModal(product)"
                  class="text-gray-400 hover:text-teal-400 transition bg-[#212529] px-3 py-1.5 rounded border border-[#2A2E33] text-xs"
                >
                  ✏️ Editar
                </button>
                <button
                  @click="confirmDelete(product)"
                  class="text-gray-400 hover:text-red-400 transition bg-[#212529] px-3 py-1.5 rounded border border-[#2A2E33] text-xs"
                >
                  🗑️ Eliminar
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="filteredProducts.length === 0">
            <td colspan="7" class="px-5 py-8 text-center text-gray-500">
              No hay productos. Crea uno nuevo o importa desde Excel.
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ProductAPI from '../../../api/products';

export default {
  name: 'Catalogo',
  data() {
    return {
      products: [],
      searchQuery: '',
      showProductModal: false,
      editingProduct: false,
      productForm: this.emptyProductForm(),
      showGoalModal: false,
      currentGoal: { month: 'Agosto', amount: 15000 },
      goalForm: { month: 'Agosto', amount: 15000 },
    };
  },
  computed: {
    ...mapGetters({
      currentAccountId: 'getCurrentAccountId',
    }),
    filteredProducts() {
      if (!this.searchQuery) return this.products;
      const q = this.searchQuery.toLowerCase();
      return this.products.filter(p => p.title.toLowerCase().includes(q));
    },
  },
  mounted() {
    this.fetchProducts();
  },
  methods: {
    emptyProductForm() {
      return {
        id: null,
        title: '',
        product_type: 'Físico',
        image_url: 'https://via.placeholder.com/40',
        description: '',
        features: '',
        stock: 0,
        cost: 0,
        price: 0,
      };
    },
    calculateMargin(product) {
      if (!product.price || product.price == 0) return 0;
      return (((product.price - product.cost) / product.price) * 100).toFixed(1);
    },
    confirmDelete(product) {
      this.$alert({
        title: '¿Eliminar producto?',
        message: `Se eliminará permanentemente "${product.title}".`,
        confirmLabel: 'Eliminar',
        cancelLabel: 'Cancelar',
        onConfirm: () => this.deleteProduct(product.id),
      });
    },

    async deleteProduct(productId) {
      try {
        await axios.delete(`/api/v1/accounts/${this.accountId}/products/${productId}`);
        this.$toast.success('Producto eliminado');
        this.fetchProducts(); // o el método que uses para recargar
      } catch (error) {
        this.$toast.error('No se pudo eliminar el producto');
      }
    },
    async fetchProducts() {
      try {
        const { data } = await ProductAPI.getProducts();
        this.products = data;
      } catch (e) {
        console.error('Error cargando productos:', e);
      }
    },
    openProductModal(product = null) {
      if (product) {
        this.editingProduct = true;
        this.productForm = { ...product };
      } else {
        this.editingProduct = false;
        this.productForm = this.emptyProductForm();
      }
      this.showProductModal = true;
    },
    closeProductModal() {
      this.showProductModal = false;
      this.productForm = this.emptyProductForm();
    },
    async saveProduct() {
      try {
        if (this.editingProduct) {
          await ProductAPI.updateProduct(this.productForm.id, this.productForm);
        } else {
          await ProductAPI.createProduct(this.productForm);
        }
        this.closeProductModal();
        this.fetchProducts();
      } catch (e) {
        console.error('Error guardando producto:', e);
      }
    },
    async handleImport(event) {
      const file = event.target.files[0];
      if (!file) return;
      try {
        await ProductAPI.importProducts(file);
        this.fetchProducts();
        event.target.value = '';
      } catch (e) {
        console.error('Error importando:', e);
      }
    },
    openGoalModal() {
      this.goalForm = { ...this.currentGoal };
      this.showGoalModal = true;
    },
    closeGoalModal() {
      this.showGoalModal = false;
    },
    saveGoal() {
      this.currentGoal = { ...this.goalForm };
      this.closeGoalModal();
    },
  },
};
</script>