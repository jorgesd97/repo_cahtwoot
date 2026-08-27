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
          <span
            v-if="hasPropias"
            class="absolute -top-1 -right-1 w-3 h-3 bg-teal-500 rounded-full border-2 border-[#0f1112]"
          />
        </button>

        <!-- WIDGET META -->
        <div class="bg-[#151718] border border-[#2A2E33] rounded-lg p-3 flex items-center space-x-4 shadow-sm">
          <div>
            <div class="text-[10px] text-gray-500 uppercase font-bold tracking-wider">
              META DE {{ currentMonthName.toUpperCase() }}
            </div>
            <div class="font-bold text-teal-400 text-xl">{{ formattedAmount }}</div>
          </div>
          <div class="w-px h-8 bg-[#2A2E33]" />
          <button
            class="inline-flex items-center justify-center w-8 h-8 rounded-lg text-slate-400 hover:text-teal-400 bg-[#1C1E23] hover:bg-[#252830] border border-[#2A2E33] hover:border-teal-500/30 transition"
            title="Editar meta"
            @click="openGoalModal"
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
      :show="showCalendar"
      :account-id="accountId"
      @close="showCalendar = false"
    />

    <!-- 💰 MODAL META -->
    <div v-if="showGoalModal" class="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center">
      <div class="bg-[#1C1E23] border border-[#2A2E33] rounded-lg w-[400px] flex flex-col shadow-2xl">
        <div class="p-5 border-b border-[#2A2E33] flex justify-between items-center">
          <h2 class="text-lg font-bold text-white">Configurar Meta Mensual</h2>
          <button @click="closeGoalModal" class="text-gray-400 hover:text-white">✕</button>
        </div>
        <div class="p-5 space-y-4 text-sm">
          <div>
            <label class="block text-gray-300 mb-1">Mes</label>
            <select v-model="goalForm.month" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 focus:border-teal-500 focus:outline-none">
              <option value="1">Enero</option>
              <option value="2">Febrero</option>
              <option value="3">Marzo</option>
              <option value="4">Abril</option>
              <option value="5">Mayo</option>
              <option value="6">Junio</option>
              <option value="7">Julio</option>
              <option value="8">Agosto</option>
              <option value="9">Septiembre</option>
              <option value="10">Octubre</option>
              <option value="11">Noviembre</option>
              <option value="12">Diciembre</option>
            </select>
          </div>
          <div>
            <label class="block text-gray-300 mb-1">Año</label>
            <input v-model.number="goalForm.year" type="number" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 focus:border-teal-500 focus:outline-none">
          </div>
          <div>
            <label class="block text-gray-300 mb-1">Monto Objetivo (S/)</label>
            <input v-model.number="goalForm.amount" type="number" step="0.01" class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-2 px-3 text-lg font-bold text-teal-400 focus:border-teal-500 focus:outline-none">
          </div>
        </div>
        <div class="p-4 border-t border-[#2A2E33] flex justify-end space-x-3 bg-[#151718] rounded-b-lg">
          <button type="button" @click="closeGoalModal" class="px-4 py-2 text-sm text-gray-400 hover:text-white transition">Cancelar</button>
          <button
            type="button"
            @click="saveGoal"
            class="bg-teal-600 hover:bg-teal-700 text-white px-6 py-2 rounded text-sm font-medium transition"
          >
            Guardar Meta
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import axios from 'axios';
import CalendarModal from './components/CalendarModal.vue';

const MONTH_NAMES = [
  'Enero','Febrero','Marzo','Abril','Mayo','Junio',
  'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'
];

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
  name: 'TiendaLayout',
  components: { CalendarModal },
  data() {
    const now = new Date();
    return {
      currentGoal: { id: null, month: now.getMonth() + 1, year: now.getFullYear(), amount: 0, currency: 'S/' },
      showCalendar: false,
      hasPropias: false,
      showGoalModal: false,
      goalForm: { month: String(now.getMonth() + 1), year: now.getFullYear(), amount: 0 },
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    currentMonthName() {
      return MONTH_NAMES[this.currentGoal.month - 1] || '—';
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
        if (this.accountId) {
          this.loadGoal();
          this.checkPropias();
        }
      },
    },
  },
  mounted() {
    if (this.accountId) {
      this.loadGoal();
      this.checkPropias();
    }
    window.addEventListener('propias-updated', this.onPropiasUpdated);
  },
  beforeUnmount() {
    window.removeEventListener('propias-updated', this.onPropiasUpdated);
  },
  methods: {
    async loadGoal() {
      if (!this.accountId) return;
      try {
        const res = await axios.get(
          `/api/v1/accounts/${this.accountId}/sales_goals/current`,
          { headers: getAuthHeaders() }
        );
        if (res.data && res.data.amount !== undefined) {
          this.currentGoal = {
            id:       res.data.id || null,
            month:    res.data.month || new Date().getMonth() + 1,
            year:     res.data.year || new Date().getFullYear(),
            amount:   parseFloat(res.data.amount) || 0,
            currency: res.data.currency || 'S/',
          };
        }
      } catch (e) {
        console.error('Error cargando meta:', e);
        const now = new Date();
        this.currentGoal = { id: null, month: now.getMonth() + 1, year: now.getFullYear(), amount: 0, currency: 'S/' };
      }
    },
    openGoalModal() {
      this.goalForm = {
        month: String(this.currentGoal.month || new Date().getMonth() + 1),
        year: this.currentGoal.year || new Date().getFullYear(),
        amount: this.currentGoal.amount || 0,
      };
      this.showGoalModal = true;
    },
    closeGoalModal() {
      this.showGoalModal = false;
    },
    async saveGoal() {
      if (!this.accountId) return;
      try {
        const payload = {
          sales_goal: {
            year:     this.goalForm.year,
            month:    parseInt(this.goalForm.month),
            amount:   this.goalForm.amount,
            currency: 'S/',
          }
        };
        const res = await axios.post(
          `/api/v1/accounts/${this.accountId}/sales_goals`,
          payload,
          { headers: getAuthHeaders() }
        );
        this.closeGoalModal();
        // Actualizar con la respuesta del servidor
        if (res.data) {
          this.currentGoal = {
            id:       res.data.id,
            month:    res.data.month,
            year:     res.data.year,
            amount:   parseFloat(res.data.amount) || 0,
            currency: res.data.currency || 'S/',
          };
        }
        if (this.$toast) this.$toast.success('Meta guardada');
      } catch (e) {
        console.error('Error guardando meta:', e);
        const msg = e.response?.data?.error?.join(', ') || 'No se pudo guardar la meta';
        if (this.$toast) this.$toast.error(msg);
        else alert(msg);
      }
    },
    checkPropias() {
      this.hasPropias = false;
    },
    onPropiasUpdated(event) {
      if (!event.detail || event.detail.accountId === this.accountId) {
        this.checkPropias();
      }
    },
  },
};
</script>
