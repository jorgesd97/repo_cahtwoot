<template>
  <div class="w-full">
    <!-- TOOLBAR CON FILTROS -->
    <div class="p-4 flex flex-wrap justify-between items-end gap-3 border-b border-[#2A2E33] bg-[#151718]">
      <div class="flex items-end gap-3 flex-wrap">
        <!-- Filtro por fecha de venta -->
        <div>
          <label class="block text-[10px] text-gray-500 uppercase font-bold tracking-wider mb-1">Fecha de Venta</label>
          <input
            v-model="filterDate"
            type="date"
            class="bg-[#1C1E23] border border-[#2A2E33] rounded-lg px-3 py-2 text-sm text-white focus:border-teal-500 focus:outline-none w-36"
            @change="fetchOrders"
          >
        </div>

        <!-- Filtro por estado -->
        <div>
          <label class="block text-[10px] text-gray-500 uppercase font-bold tracking-wider mb-1">Estado</label>
          <div class="relative">
            <select
              v-model="filterStatus"
              class="bg-[#1C1E23] border border-[#2A2E33] rounded-lg pl-3 pr-8 py-2 text-sm text-white focus:border-teal-500 focus:outline-none custom-select"
              @change="fetchOrders"
            >
              <option value="">Todos</option>
              <option value="pendiente">Pendiente</option>
              <option value="enviado">Enviado</option>
              <option value="entregado">Entregado</option>
              <option value="cancelado">Cancelado</option>
            </select>
            <svg class="absolute right-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
            </svg>
          </div>
        </div>

        <!-- Búsqueda SIN LUPA -->
        <div>
          <label class="block text-[10px] text-gray-500 uppercase font-bold tracking-wider mb-1">Buscar</label>
          <input
            v-model="searchQuery"
            type="text"
            placeholder="orden, cliente, teléfono..."
            class="bg-[#1C1E23] border border-[#2A2E33] rounded-lg px-3 py-2 text-sm text-white placeholder-gray-500 focus:border-teal-500 focus:outline-none w-56"
            @input="debounceSearch"
          >
        </div>

        <!-- Limpiar filtros -->
        <button
          v-if="hasActiveFilters"
          class="text-xs text-teal-400 hover:text-teal-300 underline pb-2"
          @click="clearFilters"
        >
          Limpiar
        </button>
      </div>

      <div class="flex items-center gap-3 pb-0">
        <!-- Contador -->
        <div class="text-sm text-gray-400">
          {{ orders.length }} orden{{ orders.length !== 1 ? 'es' : '' }}
        </div>
        <!-- BOTÓN REFRESH -->
        <button 
          @click="fetchOrders()"
          class="inline-flex items-center justify-center w-8 h-8 rounded-lg text-slate-400 hover:text-teal-400 bg-[#1C1E23] hover:bg-[#252830] border border-[#2A2E33] hover:border-teal-500/30 transition"
          title="Refrescar"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
          </svg>
        </button>
      </div>
    </div>

    <!-- TABLA -->
    <div class="bg-[#151718] rounded-b border-x border-b border-[#2A2E33] overflow-hidden">
      <table class="w-full text-left text-sm text-gray-300">
        <thead class="bg-[#151718] border-b border-[#2A2E33] text-xs text-gray-500 uppercase tracking-wide">
          <tr>
            <th class="px-5 py-4 font-medium">Nro Orden</th>
            <th class="px-5 py-4 font-medium">Fecha Venta</th>
            <th class="px-5 py-4 font-medium">Estado</th>
            <th class="px-5 py-4 font-medium">Fecha Entrega</th>
            <th class="px-5 py-4 font-medium">Pedido</th>
            <th class="px-5 py-4 font-medium">Monto</th>
            <th class="px-5 py-4 font-medium text-right">Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="order in orders" :key="order.id" class="border-b border-[#2A2E33] hover:bg-[#1C1F21] transition">
            <td class="px-5 py-4">
              <div class="font-medium text-gray-200">{{ order.order_number }}</div>
              <div class="text-[10px] text-gray-500">{{ formatDateShort(order.created_at) }}</div>
            </td>
            <td class="px-5 py-4">
              <div class="text-teal-400 text-xs font-medium">{{ formatDateLima(order.created_at) }}</div>
              <div class="text-[10px] text-gray-500">{{ formatTimeLima(order.created_at) }}</div>
            </td>
            <td class="px-5 py-4">
              <span
                class="inline-flex items-center rounded px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider border"
                :class="statusClass(order.status)"
              >
                {{ order.status }}
              </span>
            </td>
            <td class="px-5 py-4">
              <div class="text-teal-400 text-xs font-medium mb-1">{{ formatDeliveryDate(order) }}</div>
              <div class="text-[10px] text-gray-400 leading-snug">{{ order.delivery_address || '—' }}</div>
            </td>
            <td class="px-5 py-4 text-xs text-gray-300 leading-snug" v-html="formatItems(order.items_json)"></td>
            <td class="px-5 py-4 font-bold text-white">S/ {{ parseFloat(order.total_amount || 0).toFixed(2) }}</td>
            <td class="px-5 py-4 text-right">
              <div class="flex flex-col items-end gap-1.5">
                <button
                  v-if="order.status === 'pendiente'"
                  @click="updateStatus(order.id, 'enviado')"
                  class="text-gray-400 hover:text-teal-400 transition bg-[#212529] px-3 py-1.5 rounded border border-[#2A2E33] text-[10px] w-28"
                >
                  Marcar Enviado
                </button>
                <button
                  v-if="order.status === 'enviado'"
                  @click="updateStatus(order.id, 'entregado')"
                  class="text-gray-400 hover:text-green-400 transition bg-[#212529] px-3 py-1.5 rounded border border-[#2A2E33] text-[10px] w-28"
                >
                  Marcar Entregado
                </button>
                <button
                  v-if="order.status !== 'cancelado' && order.status !== 'entregado'"
                  @click="confirmCancelOrder(order)"
                  class="text-red-400 hover:text-red-300 text-[10px] uppercase font-bold mt-1 transition text-right w-28"
                >
                  Cancelar
                </button>
                <button
                  v-if="order.status === 'cancelado'"
                  @click="confirmDeleteOrder(order)"
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
          <tr v-if="orders.length === 0">
            <td colspan="7" class="px-5 py-8 text-center text-gray-500">
              No hay órdenes registradas.
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- MODAL CANCELAR ORDEN -->
    <div v-if="showCancelModal" class="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center">
      <div class="bg-[#1C1E23] border border-[#2A2E33] rounded-lg w-[400px] flex flex-col shadow-2xl">
        <div class="p-5 border-b border-[#2A2E33] flex justify-between items-center">
          <h2 class="text-lg font-bold text-white">¿Seguro que quieres cancelar?</h2>
          <button @click="showCancelModal = false" class="text-gray-400 hover:text-white">✕</button>
        </div>
        <div class="p-5 text-sm text-gray-300">
          <p>Esta acción cambiará el estado de la orden <strong>#{{ orderToCancel?.order_number }}</strong> y no se puede deshacer.</p>
        </div>
        <div class="p-4 border-t border-[#2A2E33] flex justify-end space-x-3 bg-[#151718] rounded-b-lg">
          <button @click="showCancelModal = false" class="px-4 py-2 text-sm text-gray-400 hover:text-white transition">
            Mantener orden
          </button>
          <button @click="doCancelOrder" class="bg-red-600 hover:bg-red-700 text-white px-6 py-2 rounded text-sm font-medium transition">
            Sí, Cancelar
          </button>
        </div>
      </div>
    </div>

    <!-- MODAL ELIMINAR ORDEN -->
    <div v-if="showDeleteModal" class="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center">
      <div class="bg-[#1C1E23] border border-[#2A2E33] rounded-lg w-[400px] flex flex-col shadow-2xl">
        <div class="p-5 border-b border-[#2A2E33] flex justify-between items-center">
          <h2 class="text-lg font-bold text-white">¿Seguro que quieres eliminar?</h2>
          <button @click="showDeleteModal = false" class="text-gray-400 hover:text-white">✕</button>
        </div>
        <div class="p-5 text-sm text-gray-300">
          <p>Se eliminará permanentemente la orden <strong>#{{ orderToDelete?.order_number }}</strong>. Esta acción no se puede deshacer.</p>
        </div>
        <div class="p-4 border-t border-[#2A2E33] flex justify-end space-x-3 bg-[#151718] rounded-b-lg">
          <button @click="showDeleteModal = false" class="px-4 py-2 text-sm text-gray-400 hover:text-white transition">
            Mantener
          </button>
          <button @click="deleteOrder" class="bg-red-600 hover:bg-red-700 text-white px-6 py-2 rounded text-sm font-medium transition">
            Sí, Eliminar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import axios from 'axios';
import { emitter } from 'shared/helpers/mitt';

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
      if (data['access-token'] || data['authorization']) {
        return {
          'access-token': data['access-token'],
          'client': data['client'],
          'uid': data['uid'],
        };
      }
    }
  } catch (e) {}
  try {
    const store = window.__VUE_APP__?.$store || document.querySelector('#app')?.__vue_app__?.$store;
    if (store && store.state.auth && store.state.auth.headers) {
      const h = store.state.auth.headers;
      return {
        'access-token': h['access-token'],
        'client': h['client'],
        'uid': h['uid'],
      };
    }
  } catch (e) {}
  return {};
}

function showToast(message) {
  emitter.emit('newToastMessage', { message });
}

export default {
  name: 'Ordenes',
  data() {
    return {
      orders: [],
      searchQuery: '',
      filterDate: '',
      filterStatus: '',
      isLoading: false,
      showCancelModal: false,
      orderToCancel: null,
      showDeleteModal: false,
      orderToDelete: null,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    hasActiveFilters() {
      return this.filterDate || this.filterStatus || this.searchQuery;
    },
  },
  mounted() {
    this.fetchOrders();
    window.addEventListener('open-goal-modal', this.openGoalModal);
  },
  beforeUnmount() {
    window.removeEventListener('open-goal-modal', this.openGoalModal);
  },
  methods: {
    openGoalModal() {
      if (this.$route.name !== 'tienda_catalogo') {
        this.$router.push(`/app/accounts/${this.accountId}/tienda/catalogo`);
      }
      setTimeout(() => {
        window.dispatchEvent(new CustomEvent('open-goal-modal'));
      }, 100);
    },

    async fetchOrders() {
      this.isLoading = true;
      try {
        const params = {};
        if (this.searchQuery) params.q = this.searchQuery;
        if (this.filterDate) params.created_date = this.filterDate;
        if (this.filterStatus) params.status = this.filterStatus;

        const { data } = await axios.get(`/api/v1/accounts/${this.accountId}/orders`, {
          params,
          headers: getAuthHeaders(),
        });
        this.orders = data;
      } catch (e) {
        console.error('Error fetching orders:', e);
        showToast('Error al cargar órdenes');
      } finally {
        this.isLoading = false;
      }
    },

    debounceSearch: debounce(function () {
      this.fetchOrders();
    }, 300),

    clearFilters() {
      this.filterDate = '';
      this.filterStatus = '';
      this.searchQuery = '';
      this.fetchOrders();
    },

    formatDateShort(dateStr) {
      if (!dateStr) return '';
      const d = new Date(dateStr);
      return d.toLocaleDateString('es-PE', { day: '2-digit', month: 'short' });
    },

    formatDateLima(utcDate) {
      if (!utcDate) return '';
      try {
        const date = new Date(utcDate);
        return new Intl.DateTimeFormat('es-PE', {
          timeZone: 'America/Lima',
          day: '2-digit',
          month: 'short',
          year: 'numeric',
        }).format(date);
      } catch (e) {
        return utcDate;
      }
    },

    formatTimeLima(utcDate) {
      if (!utcDate) return '';
      try {
        const date = new Date(utcDate);
        return new Intl.DateTimeFormat('es-PE', {
          timeZone: 'America/Lima',
          hour: '2-digit',
          minute: '2-digit',
        }).format(date);
      } catch (e) {
        return '';
      }
    },

    formatDeliveryDate(order) {
      if (!order.delivery_date) return 'Inmediato (Email)';
      const d = new Date(order.delivery_date);
      const h = d.getHours().toString().padStart(2, '0');
      const hEnd = (d.getHours() + 4).toString().padStart(2, '0');
      return `${d.toLocaleDateString('es-PE', { day: '2-digit', month: 'short', year: 'numeric' })}, ${h}:00 - ${hEnd}:00`;
    },

    formatItems(itemsJson) {
      try {
        const items = typeof itemsJson === 'string' ? JSON.parse(itemsJson) : itemsJson;
        if (!Array.isArray(items)) return itemsJson || '—';
        return items.map(i => `${i.qty}x ${i.title}`).join('<br>');
      } catch {
        return itemsJson || '—';
      }
    },

    statusClass(status) {
      const map = {
        pendiente: 'bg-yellow-900/30 border-yellow-800 text-yellow-500',
        enviado: 'bg-blue-900/30 border-blue-800 text-blue-400',
        entregado: 'bg-green-900/30 border-green-800 text-green-400',
        cancelado: 'bg-red-900/30 border-red-800 text-red-400',
      };
      return map[status] || 'bg-gray-900/30 border-gray-800 text-gray-500';
    },

    async updateStatus(id, newStatus) {
      const order = this.orders.find(o => o.id === id);
      const oldStatus = order ? order.status : null;

      if (order) order.status = newStatus;

      try {
        await axios.patch(`/api/v1/accounts/${this.accountId}/orders/${id}`, {
          order: { status: newStatus },
        }, { headers: getAuthHeaders() });
        showToast(`Orden marcada como ${newStatus}`);
      } catch {
        if (order) order.status = oldStatus;
        showToast('Error al actualizar estado');
      }
    },

    confirmCancelOrder(order) {
      this.orderToCancel = order;
      this.showCancelModal = true;
    },

    async doCancelOrder() {
      if (!this.orderToCancel) return;
      const order = this.orders.find(o => o.id === this.orderToCancel.id);
      const oldStatus = order ? order.status : null;

      if (order) order.status = 'cancelado';

      try {
        await axios.patch(`/api/v1/accounts/${this.accountId}/orders/${this.orderToCancel.id}`, {
          order: { status: 'cancelado' },
        }, { headers: getAuthHeaders() });
        showToast('Orden cancelada');
      } catch {
        if (order) order.status = oldStatus;
        showToast('Error al cancelar orden');
      } finally {
        this.showCancelModal = false;
        this.orderToCancel = null;
      }
    },

    confirmDeleteOrder(order) {
      this.orderToDelete = order;
      this.showDeleteModal = true;
    },

    async deleteOrder() {
      if (!this.orderToDelete) return;
      try {
        await axios.delete(`/api/v1/accounts/${this.accountId}/orders/${this.orderToDelete.id}`, {
          headers: getAuthHeaders(),
        });
        this.orders = this.orders.filter(o => o.id !== this.orderToDelete.id);
        showToast('Orden eliminada');
        await this.fetchOrders();
      } catch (error) {
        console.error('Error deleting order:', error);
        showToast('No se pudo eliminar la orden');
      } finally {
        this.showDeleteModal = false;
        this.orderToDelete = null;
      }
    },
  },
};
</script>

<style scoped>
/* Oculta la flecha nativa del select en TODOS los navegadores */
.custom-select {
  -webkit-appearance: none;
  -moz-appearance: none;
  appearance: none;
  background-image: none;
}

/* Icono del calendario en blanco para el tema oscuro */
input[type="date"]::-webkit-calendar-picker-indicator {
  filter: invert(1);
  opacity: 0.6;
  cursor: pointer;
}
input[type="date"]::-webkit-calendar-picker-indicator:hover {
  opacity: 1;
}
</style>