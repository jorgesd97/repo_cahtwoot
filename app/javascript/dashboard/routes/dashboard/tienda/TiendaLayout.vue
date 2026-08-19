<template>
  <div class="flex flex-col h-full w-full">
    <!-- HEADER -->
    <div class="flex justify-between items-start mb-6 px-8 pt-8">
      <div>
        <h1 class="text-2xl font-bold text-white">Tienda & Órdenes</h1>
        <p class="text-sm text-gray-400 mt-1">Controla tu catálogo, despachos y métricas de venta.</p>
      </div>

      <div class="flex items-center gap-3">
        <!-- 🗓️ BOTÓN CALENDARIO -->
        <button
          class="relative inline-flex items-center justify-center w-10 h-10 rounded-lg text-slate-400 hover:text-teal-400 bg-[#1C1E23] hover:bg-[#252830] border border-[#2A2E33] hover:border-teal-500/30 transition"
          title="Calendario"
          @click="showCalendar = true"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <rect x="3" y="4" width="18" height="18" rx="2" ry="2" stroke-width="2" />
            <line x1="16" y1="2" x2="16" y2="6" stroke-width="2" />
            <line x1="8" y1="2" x2="8" y2="6" stroke-width="2" />
            <line x1="3" y1="10" x2="21" y2="10" stroke-width="2" />
          </svg>
          <!-- Badge si hay días propios -->
          <span
            v-if="hasPropias"
            class="absolute -top-1 -right-1 w-3 h-3 bg-teal-500 rounded-full border-2 border-[#0f1112]"
          />
        </button>

        <!-- WIDGET META -->
        <div class="bg-[#151718] border border-[#2A2E33] rounded-lg p-3 flex items-center space-x-4 shadow-sm">
          <div>
            <div class="text-[10px] text-gray-500 uppercase font-bold tracking-wider">META DE {{ currentGoal.month.toUpperCase() }}</div>
            <div class="font-bold text-teal-400 text-xl">{{ formattedAmount }}</div>
          </div>
          <div class="w-px h-8 bg-[#2A2E33]" />
          <button
            class="inline-flex items-center justify-center w-8 h-8 rounded-lg text-slate-400 hover:text-teal-400 bg-[#1C1E23] hover:bg-[#252830] border border-[#2A2E33] hover:border-teal-500/30 transition"
            title="Editar meta"
            @click="triggerEditGoal"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
            </svg>
          </button>
        </div>
      </div>
    </div>

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

    <!-- 🗓️ MODAL CALENDARIO -->
    <calendar-modal
      :show.sync="showCalendar"
      :account-id="accountId"
      @close="showCalendar = false"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import CalendarModal from './components/CalendarModal.vue';

export default {
  name: 'TiendaLayout',
  components: { CalendarModal },
  data() {
    return {
      currentGoal: { month: 'Agosto', amount: 15000 },
      showCalendar: false,
      hasPropias: false,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    goalStorageKey() {
      return `tienda_goal_account_${this.accountId}`;
    },
    propiasStorageKey() {
      return `tienda_propias_2026_account_${this.accountId}`;
    },
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
  watch: {
    accountId: {
      immediate: true,
      handler() {
        this.loadGoal();
        this.checkPropias();
      },
    },
  },
  mounted() {
    this.loadGoal();
    this.checkPropias();
    window.addEventListener('goal-updated', this.onGoalUpdated);
    window.addEventListener('propias-updated', this.onPropiasUpdated);
  },
  beforeUnmount() {
    window.removeEventListener('goal-updated', this.onGoalUpdated);
    window.removeEventListener('propias-updated', this.onPropiasUpdated);
  },
  methods: {
    loadGoal() {
      if (!this.accountId) return;
      try {
        const saved = localStorage.getItem(this.goalStorageKey);
        if (saved) {
          this.currentGoal = JSON.parse(saved);
        } else {
          // Default si no hay nada guardado para esta cuenta
          this.currentGoal = { month: 'Agosto', amount: 15000 };
        }
      } catch (e) {
        console.error('Error loading goal:', e);
        this.currentGoal = { month: 'Agosto', amount: 15000 };
      }
    },
    onGoalUpdated(event) {
      // Solo recargar si el evento es para la cuenta actual
      if (!event.detail || event.detail.accountId === this.accountId) {
        this.loadGoal();
      }
    },
    triggerEditGoal() {
      window.dispatchEvent(new CustomEvent('open-goal-modal'));
    },
    checkPropias() {
      if (!this.accountId) {
        this.hasPropias = false;
        return;
      }
      try {
        const saved = localStorage.getItem(this.propiasStorageKey);
        this.hasPropias = saved ? JSON.parse(saved).length > 0 : false;
      } catch (e) {
        this.hasPropias = false;
      }
    },
    onPropiasUpdated(event) {
      // Solo recargar si el evento es para la cuenta actual
      if (!event.detail || event.detail.accountId === this.accountId) {
        this.checkPropias();
      }
    },
  },
};
</script>
