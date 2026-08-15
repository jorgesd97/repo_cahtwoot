<template>
  <div class="flex flex-col h-full w-full">
    <!-- HEADER -->
    <div class="flex justify-between items-start mb-6 px-8 pt-8">
      <div>
        <h1 class="text-2xl font-bold text-white">Tienda & Órdenes</h1>
        <p class="text-sm text-gray-400 mt-1">Controla tu catálogo, despachos y métricas de venta.</p>
      </div>
      
      <!-- WIDGET META -->
      <div class="bg-[#151718] border border-[#2A2E33] rounded-lg p-3 flex items-center space-x-4 shadow-sm">
        <div>
          <div class="text-[10px] text-gray-500 uppercase font-bold tracking-wider">META DE {{ currentGoal.month.toUpperCase() }}</div>
          <div class="font-bold text-teal-400 text-xl">{{ formattedAmount }}</div>
        </div>
        <div class="w-px h-8 bg-[#2A2E33]"></div>
        <button 
  @click="triggerEditGoal"
  class="inline-flex items-center justify-center w-8 h-8 rounded-lg text-slate-400 hover:text-teal-400 bg-[#1C1E23] hover:bg-[#252830] border border-[#2A2E33] hover:border-teal-500/30 transition"
  title="Editar meta"
>
  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/>
  </svg>
</button>
      </div>
    </div>    <!-- ✅ AQUÍ FALTABA ESTE </div> -->

    <!-- TABS -->
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

    <!-- CONTENIDO DINÁMICO -->
    <div class="flex-1 overflow-auto px-8 pb-8 w-full">
      <router-view />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  name: 'TiendaLayout',
  data() {
    return {
      currentGoal: { month: 'Agosto', amount: 15000 },
    };
  },
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
    formattedAmount() {
      return new Intl.NumberFormat('es-PE', {
        style: 'currency',
        currency: 'PEN',
        minimumFractionDigits: 2,
      }).format(this.currentGoal.amount || 0);
    },
  },
  mounted() {
    this.loadGoal();
    window.addEventListener('goal-updated', this.loadGoal);
  },
  beforeUnmount() {
    window.removeEventListener('goal-updated', this.loadGoal);
  },
  methods: {
    loadGoal() {
      try {
        const saved = localStorage.getItem('tienda_goal');
        if (saved) {
          this.currentGoal = JSON.parse(saved);
        }
      } catch (e) {
        console.error('Error loading goal:', e);
      }
    },
    triggerEditGoal() {
      window.dispatchEvent(new CustomEvent('open-goal-modal'));
    },
  },
};
</script>