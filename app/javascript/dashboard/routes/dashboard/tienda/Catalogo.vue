<template>
  <div class="w-full">
    <!-- TOOLBAR -->
    <div class="p-4 flex justify-between items-center border-b border-[#2A2E33] bg-[#151718]">
                  <div class="relative w-72">
  <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
    <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
    </svg>
  </div>
  <input 
    type="text" 
    placeholder="Buscar producto..." 
    class="block w-full rounded-lg border border-[#2A2E33] bg-[#151718] py-2.5 pl-11 pr-4 text-sm text-slate-200 placeholder-slate-500 focus:border-teal-500/50 focus:outline-none focus:ring-1 focus:ring-teal-500/20"
    v-model="searchQuery"
    @input="debounceSearch"
  >
</div>
      <div class="flex items-center gap-3">
        <input 
          ref="fileInput"
          type="file" 
          accept=".xlsx,.xls,.csv"
          class="hidden"
          @change="handleImport"
        >
        <button 
          @click="$refs.fileInput.click()"
          class="bg-[#212529] text-gray-300 px-4 py-2 rounded text-sm border border-[#2A2E33] hover:border-gray-500 transition flex items-center"
        >
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
                  class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium text-slate-400 hover:text-teal-400 bg-[#1C1E23] hover:bg-[#252830] border border-[#2A2E33] hover:border-teal-500/30 transition"
                >
                  <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/>
                  </svg>
                  Editar
                </button>
                <button
                  @click="confirmDelete(product)"
                  class="inline-flex items-center gap-1 text-xs font-medium text-red-500 hover:text-red-400 transition hover:underline"
                >
                  <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                  </svg>
                  Eliminar
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

    <!-- MODAL PRODUCTO -->
    <div v-if="showProductModal" class="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center">
      <div class="bg-[#1C1E23] border border-[#2A2E33] rounded-lg w-[600px] max-h-[90vh] flex flex-col shadow-2xl">
        <div class="p-5 border-b border-[#2A2E33] flex justify-between items-center">
          <h2 class="text-lg font-bold text-white">{{ editingProduct ? 'Editar Producto' : 'Nuevo Producto' }}</h2>
          <button @click="closeProductModal" class="text-gray-400 hover:text-white">✕</button>
        </div>
        <form @submit.prevent="saveProduct" class="flex flex-col flex-1 overflow-hidden">
          <div class="p-5 overflow-y-auto space-y-4 text-sm flex-1">
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-gray-300 mb-1">Título *</label>
                <input v-model="productForm.title" type="text" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 focus:border-teal-500 focus:outline-none" required>
              </div>
              <div>
                <label class="block text-gray-300 mb-1">Tipo *</label>
                <select v-model="productForm.product_type" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 focus:border-teal-500 focus:outline-none" required>
                  <option value="Físico">Físico</option>
                  <option value="Intangible">Intangible</option>
                </select>
              </div>
            </div>
            <div>
              <label class="block text-gray-300 mb-1">Imagen URL</label>
              <input v-model="productForm.image_url" type="text" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 focus:border-teal-500 focus:outline-none">
            </div>
            <div>
              <label class="block text-gray-300 mb-1">Descripción</label>
              <textarea v-model="productForm.description" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 h-16 focus:border-teal-500 focus:outline-none"></textarea>
            </div>
            <div>
              <label class="block text-gray-300 mb-1">Características</label>
              <textarea v-model="productForm.features" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 h-12 focus:border-teal-500 focus:outline-none"></textarea>
            </div>
            <div class="grid grid-cols-3 gap-4">
              <div>
                <label class="block text-gray-300 mb-1">Stock *</label>
                <input v-model.number="productForm.stock" type="number" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 focus:border-teal-500 focus:outline-none" required>
              </div>
              <div>
                <label class="block text-gray-300 mb-1">Costo (S/) *</label>
                <input v-model.number="productForm.cost" type="number" step="0.01" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 focus:border-teal-500 focus:outline-none" required>
              </div>
              <div>
                <label class="block text-gray-300 mb-1">Precio (S/) *</label>
                <input v-model.number="productForm.price" type="number" step="0.01" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 focus:border-teal-500 focus:outline-none" required>
              </div>
            </div>
          </div>
          <div class="p-5 border-t border-[#2A2E33] flex justify-end space-x-3 bg-[#151718] rounded-b-lg">
            <button type="button" @click="closeProductModal" class="px-4 py-2 text-sm text-gray-400 hover:text-white transition">Cancelar</button>
            <button type="submit" class="bg-teal-600 hover:bg-teal-700 text-white px-6 py-2 rounded text-sm font-medium transition">Guardar</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL META -->
    <div v-if="showGoalModal" class="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center">
      <div class="bg-[#1C1E23] border border-[#2A2E33] rounded-lg w-[400px] flex flex-col shadow-2xl">
        <div class="p-5 border-b border-[#2A2E33] flex justify-between items-center">
          <h2 class="text-lg font-bold text-white">Configurar Meta Mensual</h2>
          <button @click="closeGoalModal" class="text-gray-400 hover:text-white">✕</button>
        </div>
        <form @submit.prevent="saveGoal">
          <div class="p-5 space-y-4 text-sm">
            <div>
              <label class="block text-gray-300 mb-1">Mes</label>
              <select v-model="goalForm.month" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 focus:border-teal-500 focus:outline-none" required>
                <option>Agosto</option>
                <option>Septiembre</option>
                <option>Octubre</option>
              </select>
            </div>
            <div>
              <label class="block text-gray-300 mb-1">Monto Objetivo (S/)</label>
              <input v-model.number="goalForm.amount" type="number" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 text-lg font-bold text-teal-400 focus:border-teal-500 focus:outline-none" required>
            </div>
          </div>
          <div class="p-4 border-t border-[#2A2E33] flex justify-end space-x-3 bg-[#151718] rounded-b-lg">
            <button type="button" @click="closeGoalModal" class="px-4 py-2 text-sm text-gray-400 hover:text-white transition">Cancelar</button>
            <button type="submit" class="bg-teal-600 hover:bg-teal-700 text-white px-6 py-2 rounded text-sm font-medium transition">Guardar Meta</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL ELIMINAR -->
    <div v-if="showDeleteModal" class="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center">
      <div class="bg-[#1C1E23] border border-[#2A2E33] rounded-lg w-[400px] flex flex-col shadow-2xl">
        <div class="p-5 border-b border-[#2A2E33] flex justify-between items-center">
          <h2 class="text-lg font-bold text-white">¿Seguro que quieres eliminar?</h2>
          <button @click="showDeleteModal = false" class="text-gray-400 hover:text-white">✕</button>
        </div>
        <div class="p-5 text-sm text-gray-300">
          <p>Se eliminará permanentemente <strong>"{{ productToDelete?.title }}"</strong>. Esta acción no se puede deshacer.</p>
        </div>
        <div class="p-4 border-t border-[#2A2E33] flex justify-end space-x-3 bg-[#151718] rounded-b-lg">
          <button @click="showDeleteModal = false" class="px-4 py-2 text-sm text-gray-400 hover:text-white transition">
            Mantener
          </button>
          <button @click="deleteProduct" class="bg-red-600 hover:bg-red-700 text-white px-6 py-2 rounded text-sm font-medium transition">
            Sí, Eliminar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ProductAPI from '../../../api/products';
import axios from 'axios';

function debounce(fn, delay) {
  let timeoutId;
  return function (...args) {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn.apply(this, args), delay);
  };
}

function getAuthHeaders() {
  try {
    const raw = localStorage.getItem('auth_headers');
    if (raw) {
      const h = JSON.parse(raw);
      if (h['access-token']) {
        return {
          'access-token': h['access-token'],
          'client': h['client'],
          'uid': h['uid'],
        };
      }
    }
  } catch (e) {}
  try {
    const match = document.cookie.match(/cw_d_session_info=([^;]+)/);
    if (match) {
      const data = JSON.parse(decodeURIComponent(match[1]));
      return {
        'access-token': data['access-token'],
        'client': data['client'],
        'uid': data['uid'],
      };
    }
  } catch (e) {}
  return {};
}

export default {
  name: 'Catalogo',
  data() {
    return {
      products: [],
      searchQuery: '',
      showDeleteModal: false,
      productToDelete: null,
      showProductModal: false,
      editingProduct: false,
      productForm: {
        id: null,
        title: '',
        product_type: 'Físico',
        image_url: 'https://via.placeholder.com/40',
        description: '',
        features: '',
        stock: 0,
        cost: 0,
        price: 0,
      },
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
  window.addEventListener('open-goal-modal', this.openGoalModal);
  
  // Cargar meta guardada si existe
  try {
    const saved = localStorage.getItem('tienda_goal');
    if (saved) this.currentGoal = JSON.parse(saved);
  } catch (e) {}
  },
  beforeUnmount() {
    // ✅ Vue 3 usa beforeUnmount (no beforeDestroy)
    window.removeEventListener('open-goal-modal', this.openGoalModal);
  },
  methods: {
    calculateMargin(product) {
      if (!product.price || product.price == 0) return 0;
      return (((product.price - product.cost) / product.price) * 100).toFixed(1);
    },
    confirmDelete(product) {
      this.productToDelete = product;
      this.showDeleteModal = true;
    },
    async deleteProduct() {
      if (!this.productToDelete) return;
      try {
        await axios.delete(`/api/v1/accounts/${this.currentAccountId}/products/${this.productToDelete.id}`, {
          headers: getAuthHeaders(),
        });
        // ✅ Eliminar localmente primero (feedback inmediato)
        this.products = this.products.filter(p => p.id !== this.productToDelete.id);
        this.$toast.success('Producto eliminado');
        // Refrescar desde servidor por si acaso
        await this.fetchProducts();
      } catch (error) {
        console.error('Error deleting product:', error);
        this.$toast.error('No se pudo eliminar el producto');
      } finally {
        this.showDeleteModal = false;
        this.productToDelete = null;
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
        this.productForm = {
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
      }
      this.showProductModal = true;
    },
    closeProductModal() {
      this.showProductModal = false;
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
        this.$toast.error('Error al guardar producto');
      }
    },
    async handleImport(event) {
      const file = event.target.files[0];
      if (!file) return;
      try {
        await ProductAPI.importProducts(file);
        this.fetchProducts();
        event.target.value = '';
        this.$toast.success('Productos importados');
      } catch (e) {
        console.error('Error importando:', e);
        this.$toast.error('Error al importar');
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
  localStorage.setItem('tienda_goal', JSON.stringify(this.currentGoal));
  window.dispatchEvent(new CustomEvent('goal-updated'));
  this.closeGoalModal();
  this.$toast.success('Meta actualizada');
},
    debounceSearch: debounce(function () {
      // Si tu ProductAPI soporte búsqueda, úsala aquí
      // Por ahora solo filtra el array local
    }, 300),
  },
};
</script>