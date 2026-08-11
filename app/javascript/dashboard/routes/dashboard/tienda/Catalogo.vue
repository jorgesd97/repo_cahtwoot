<template>
  <div class="flex flex-col h-full overflow-hidden bg-[#1C1E23]">
    
    <!-- HEADER -->
    <div class="flex items-center justify-between px-8 pt-8 pb-2">
      <div>
        <h1 class="text-2xl font-bold text-white">Tienda & Órdenes</h1>
        <p class="text-sm text-gray-400 mt-1">Controla tu catálogo, despachos y métricas de venta.</p>
      </div>
      
      <!-- WIDGET META MENSUAL -->
      <div class="bg-[#151718] border border-[#2A2E33] rounded-lg px-4 py-3 flex items-center gap-4">
        <div>
          <div class="text-[10px] text-gray-500 uppercase font-bold tracking-wider">
            Meta de {{ currentGoal.month }}
          </div>
          <div class="font-bold text-xl" style="color: #14B8A6;">
            S/ {{ parseFloat(currentGoal.amount).toLocaleString('en-US', {minimumFractionDigits: 2}) }}
          </div>
        </div>
        <div class="w-px h-8 bg-[#2A2E33]"></div>
        <button 
          @click="openGoalModal"
          class="text-gray-400 hover:text-white p-1.5 bg-[#212529] rounded border border-[#2A2E33]"
          title="Editar Meta"
        >
          ✏️
        </button>
      </div>
    </div>

    <!-- TABS -->
    <div class="px-8 border-b border-[#2A2E33] mt-6 flex gap-6">
      <router-link
        :to="{ name: 'tienda_catalogo', params: { accountId: currentAccountId } }"
        class="pb-3 px-1 text-sm font-medium border-b-2 transition"
        :class="$route.name === 'tienda_catalogo' ? 'border-teal-500 text-teal-400' : 'border-transparent text-gray-400 hover:text-gray-300'"
      >
        Catálogo
      </router-link>
      <router-link
        :to="{ name: 'tienda_ordenes', params: { accountId: currentAccountId } }"
        class="pb-3 px-1 text-sm font-medium border-b-2 border-transparent text-gray-400 hover:text-gray-300 transition"
      >
        Lista de Órdenes
      </router-link>
    </div>

    <!-- TOOLBAR -->
    <div class="px-8 py-4 flex justify-between items-center">
      <div class="w-64">
        <input 
          v-model="searchQuery"
          type="text" 
          placeholder="🔍 Buscar producto..." 
          class="bg-[#151718] border border-[#2A2E33] text-white text-sm rounded w-full py-1.5 px-3 focus:border-teal-500 focus:outline-none"
        />
      </div>
      <div class="flex gap-2">
        <label class="cursor-pointer bg-[#212529] hover:bg-[#2A2E33] text-gray-300 px-4 py-2 rounded text-sm font-medium transition flex items-center gap-2 border border-[#2A2E33]">
          📄 Importar Excel
          <input type="file" accept=".xlsx,.xls,.csv" class="hidden" @change="handleImport" />
        </label>
        
        <button 
          @click="openProductModal()"
          class="text-white px-4 py-2 rounded text-sm font-medium transition flex items-center gap-2"
          style="background-color: #14B8A6;"
          onmouseover="this.style.backgroundColor='#0D9488'"
          onmouseout="this.style.backgroundColor='#14B8A6'"
        >
          + Nuevo Producto
        </button>
      </div>
    </div>

    <!-- TABLA -->
    <div class="flex-1 overflow-auto px-8 pb-8">
      <div class="bg-[#151718] rounded border border-[#2A2E33] overflow-hidden">
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
            <tr 
              v-for="product in filteredProducts" 
              :key="product.id" 
              class="border-b border-[#2A2E33] hover:bg-[#212529] transition"
            >
              <td class="px-5 py-4 flex items-center gap-3">
                <img :src="product.image_url || 'https://via.placeholder.com/40'" class="w-8 h-8 rounded border border-[#2A2E33]" />
                <span class="font-medium text-gray-200">{{ product.title }}</span>
              </td>
              <td class="px-5 py-4 text-xs text-gray-400">{{ product.product_type }}</td>
              <td class="px-5 py-4">
                <span :class="product.stock < 10 ? 'text-red-400 font-bold' : 'text-gray-300'">
                  {{ product.stock }}
                </span>
                <span v-if="product.stock < 10" class="text-red-400 text-xs"> (Bajo)</span>
              </td>
              <td class="px-5 py-4">S/ {{ parseFloat(product.cost || 0).toFixed(2) }}</td>
              <td class="px-5 py-4">S/ {{ parseFloat(product.price || 0).toFixed(2) }}</td>
              <td class="px-5 py-4">
                <span class="text-green-400 text-sm font-semibold">{{ calculateMargin(product) }}%</span>
              </td>
              <td class="px-5 py-4 text-right">
                <button 
                  @click="openProductModal(product)"
                  class="text-gray-400 hover:text-teal-400 transition bg-[#212529] px-3 py-1.5 rounded border border-[#2A2E33] text-xs"
                >
                  ✏️ Editar
                </button>
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

    <!-- MODAL PRODUCTO -->
    <div v-if="showProductModal" class="fixed inset-0 bg-black/75 z-50 flex items-center justify-center" @click.self="closeProductModal">
      <div class="bg-[#1C1E23] border border-[#2A2E33] rounded-lg w-[600px] max-h-[90vh] overflow-y-auto shadow-2xl">
        <div class="p-5 border-b border-[#2A2E33] flex justify-between items-center">
          <h2 class="text-lg font-bold text-white">{{ editingProduct ? 'Editar Producto' : 'Nuevo Producto' }}</h2>
          <button @click="closeProductModal" class="text-gray-400 hover:text-white text-xl">✕</button>
        </div>
        <form @submit.prevent="saveProduct" class="p-5 space-y-4 text-sm">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-gray-300 mb-1">Título *</label>
              <input v-model="productForm.title" type="text" class="bg-[#151718] border border-[#2A2E33] text-white rounded w-full py-2 px-3 focus:border-teal-500 focus:outline-none" required />
            </div>
            <div>
              <label class="block text-gray-300 mb-1">Tipo *</label>
              <select v-model="productForm.product_type" class="bg-[#151718] border border-[#2A2E33] text-white rounded w-full py-2 px-3 focus:border-teal-500 focus:outline-none" required>
                <option value="Físico">Físico</option>
                <option value="Intangible">Intangible</option>
              </select>
            </div>
          </div>
          <div>
            <label class="block text-gray-300 mb-1">Imagen URL</label>
            <input v-model="productForm.image_url" type="text" class="bg-[#151718] border border-[#2A2E33] text-white rounded w-full py-2 px-3 focus:border-teal-500 focus:outline-none" />
          </div>
          <div>
            <label class="block text-gray-300 mb-1">Descripción</label>
            <textarea v-model="productForm.description" rows="2" class="bg-[#151718] border border-[#2A2E33] text-white rounded w-full py-2 px-3 focus:border-teal-500 focus:outline-none"></textarea>
          </div>
          <div>
            <label class="block text-gray-300 mb-1">Características</label>
            <textarea v-model="productForm.features" rows="2" class="bg-[#151718] border border-[#2A2E33] text-white rounded w-full py-2 px-3 focus:border-teal-500 focus:outline-none"></textarea>
          </div>
          <div class="grid grid-cols-3 gap-4">
            <div>
              <label class="block text-gray-300 mb-1">Stock *</label>
              <input v-model.number="productForm.stock" type="number" min="0" class="bg-[#151718] border border-[#2A2E33] text-white rounded w-full py-2 px-3 focus:border-teal-500 focus:outline-none" required />
            </div>
            <div>
              <label class="block text-gray-300 mb-1">Costo (S/) *</label>
              <input v-model.number="productForm.cost" type="number" step="0.1" min="0" class="bg-[#151718] border border-[#2A2E33] text-white rounded w-full py-2 px-3 focus:border-teal-500 focus:outline-none" required />
            </div>
            <div>
              <label class="block text-gray-300 mb-1">Precio (S/) *</label>
              <input v-model.number="productForm.price" type="number" step="0.1" min="0" class="bg-[#151718] border border-[#2A2E33] text-white rounded w-full py-2 px-3 focus:border-teal-500 focus:outline-none" required />
            </div>
          </div>
          <div class="flex justify-end gap-3 pt-2">
            <button type="button" @click="closeProductModal" class="px-4 py-2 text-sm text-gray-400 hover:text-white transition">Cancelar</button>
            <button type="submit" class="bg-teal-600 hover:bg-teal-700 text-white px-6 py-2 rounded text-sm font-medium transition">Guardar</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL META -->
    <div v-if="showGoalModal" class="fixed inset-0 bg-black/75 z-50 flex items-center justify-center" @click.self="closeGoalModal">
      <div class="bg-[#1C1E23] border border-[#2A2E33] rounded-lg w-[400px] shadow-2xl">
        <div class="p-5 border-b border-[#2A2E33] flex justify-between items-center">
          <h2 class="text-lg font-bold text-white">Configurar Meta Mensual</h2>
          <button @click="closeGoalModal" class="text-gray-400 hover:text-white text-xl">✕</button>
        </div>
        <form @submit.prevent="saveGoal" class="p-5 space-y-4 text-sm">
          <div>
            <label class="block text-gray-300 mb-1">Mes</label>
            <select v-model="goalForm.month" class="bg-[#151718] border border-[#2A2E33] text-white rounded w-full py-2 px-3 focus:border-teal-500 focus:outline-none">
              <option value="Agosto">Agosto</option>
              <option value="Septiembre">Septiembre</option>
              <option value="Octubre">Octubre</option>
            </select>
          </div>
          <div>
            <label class="block text-gray-300 mb-1">Monto Objetivo (S/)</label>
            <input v-model.number="goalForm.amount" type="number" step="0.01" class="bg-[#151718] border border-[#2A2E33] text-white rounded w-full py-2 px-3 text-lg font-bold text-teal-400 focus:border-teal-500 focus:outline-none" required />
          </div>
          <div class="flex justify-end gap-3 pt-2">
            <button type="button" @click="closeGoalModal" class="px-4 py-2 text-sm text-gray-400 hover:text-white transition">Cancelar</button>
            <button type="submit" class="bg-teal-600 hover:bg-teal-700 text-white px-6 py-2 rounded text-sm font-medium transition">Guardar Meta</button>
          </div>
        </form>
      </div>
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