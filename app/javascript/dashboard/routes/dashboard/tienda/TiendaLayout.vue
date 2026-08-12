<template>
  <div class="flex flex-col h-full w-full">
    <!-- HEADER FIJO — no se mueve al cambiar de pestaña -->
    <div class="flex justify-between items-start mb-6 px-8 pt-8">
      <div>
        <h1 class="text-2xl font-bold text-white">Tienda & Órdenes</h1>
        <p class="text-sm text-gray-400 mt-1">Controla tu catálogo, despachos y métricas de venta.</p>
      </div>
      
      <!-- WIDGET META -->
      <div class="bg-[#151718] border border-[#2A2E33] rounded-lg p-3 flex items-center space-x-4 shadow-sm">
        <div>
          <div class="text-[10px] text-gray-500 uppercase font-bold tracking-wider">META DE AGOSTO</div>
          <div class="font-bold text-teal-400 text-xl">S/ 15,000.00</div>
        </div>
        <div class="w-px h-8 bg-[#2A2E33]"></div>
        <button class="text-gray-400 hover:text-white transition px-2 py-1 bg-[#212529] rounded border border-[#2A2E33]" title="Editar Meta">
          <span class="text-sm">✏️</span>
        </button>
      </div>
    </div>

    <!-- TABS FIJAS -->
    <div class="border-b border-[#2A2E33] mb-6 flex space-x-6 px-8">
      <router-link
        :to="catalogoRoute"
        class="pb-3 px-1 text-sm font-medium transition-colors border-b-2"
        :class="isCatalogo ? 'border-teal-500 text-teal-400' : 'border-transparent text-gray-400 hover:text-gray-300'"
      >
        Catálogo
      </router-link>
      <router-link
        :to="ordenesRoute"
        class="pb-3 px-1 text-sm font-medium transition-colors border-b-2"
        :class="isOrdenes ? 'border-teal-500 text-teal-400' : 'border-transparent text-gray-400 hover:text-gray-300'"
      >
        Lista de Órdenes
      </router-link>
    </div>

    <!-- CONTENIDO DINÁMICO — solo esto cambia -->
    <div class="flex-1 overflow-auto px-8 pb-8 w-full">
      <router-view />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  name: 'TiendaLayout',
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    catalogoRoute() {
      return `/app/accounts/${this.accountId}/tienda/catalogo`;
    },
    ordenesRoute() {
      return `/app/accounts/${this.accountId}/tienda/ordenes`;
    },
    isCatalogo() {
      return this.$route.name === 'tienda_catalogo';
    },
    isOrdenes() {
      return this.$route.name === 'tienda_ordenes';
    },
  },
};
</script>