<template>
  <woot-modal :show.sync="show" size="medium" @close="onClose">
    <div class="calendar-modal">
      <!-- Header -->
      <div class="calendar-header">
        <div class="calendar-nav">
          <button class="nav-btn" :disabled="currentMonth === 0" @click="prevMonth">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
            </svg>
          </button>
          <h2 class="month-title">{{ monthName }} 2026</h2>
          <button class="nav-btn" :disabled="currentMonth === 11" @click="nextMonth">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
            </svg>
          </button>
        </div>
      </div>

      <!-- Filtro -->
      <div class="calendar-filter">
        <label class="filter-toggle">
          <input v-model="showOnlyPropias" type="checkbox" @change="loadEvents">
          <span class="toggle-slider" />
          <span class="toggle-label">Solo mostrar días propios</span>
        </label>
      </div>

      <!-- Días de la semana -->
      <div class="weekdays-grid">
        <div v-for="day in weekDays" :key="day" class="weekday-label">{{ day }}</div>
      </div>

      <!-- Grid de días -->
      <div class="days-grid">
        <div
          v-for="(day, idx) in calendarDays"
          :key="idx"
          class="day-cell"
          :class="dayCellClasses(day)"
          @mouseenter="onDayHover(day, $event)"
          @mouseleave="hoveredDay = null"
          @click="day && onDayClick(day)"
        >
          <span v-if="day" class="day-number">{{ day.date.getDate() }}</span>
          <div v-if="day && getEventsForDay(day.date).length > 0" class="event-dots">
            <div
              v-for="(evt, i) in getEventsForDay(day.date).slice(0, 3)"
              :key="i"
              class="event-dot"
              :style="{ background: getCategoryColor(evt.category) }"
            />
          </div>
        </div>
      </div>

      <!-- Tooltip flotante -->
      <div
        v-if="hoveredDay && getEventsForDay(hoveredDay.date).length > 0"
        class="day-tooltip"
        :style="tooltipStyle"
      >
        <div class="tooltip-date">{{ formatFullDate(hoveredDay.date) }}</div>
        <div v-for="evt in getEventsForDay(hoveredDay.date)" :key="evt.id" class="tooltip-event">
          <div class="tooltip-dot" :style="{ background: getCategoryColor(evt.category) }" />
          <span class="tooltip-title">{{ evt.title }}</span>
          <span class="tooltip-badge" :style="getBadgeStyle(evt.category)">
            {{ getCategoryLabel(evt.category) }}
          </span>
        </div>
        <div class="tooltip-arrow" />
      </div>

      <!-- Footer con leyenda dinámica -->
      <div class="calendar-footer">
        <div class="legend">
          <div v-for="cat in activeCategories" :key="cat.key" class="legend-item">
            <div class="legend-dot" :style="{ background: cat.color }" />
            <span class="legend-text">{{ cat.label }}</span>
          </div>
        </div>
        <button class="add-btn" @click="openAddModal">
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
          Agregar día
        </button>
      </div>
    </div>

    <!-- Modal Detalle del Día -->
    <woot-modal v-if="selectedDay" :show.sync="showDayDetail" size="small" @close="selectedDay = null">
      <div class="day-detail">
        <div class="day-detail-header">
          <h3>{{ formatFullDate(selectedDay.date) }}</h3>
        </div>

        <div v-if="getEventsForDay(selectedDay.date).length === 0" class="empty-state">
          No hay eventos registrados este día
        </div>

        <div
          v-for="evt in getEventsForDay(selectedDay.date)"
          :key="evt.id"
          class="event-card"
          :style="getCardStyle(evt.category)"
        >
          <div class="event-info">
            <div class="event-dot-lg" :style="{ background: getCategoryColor(evt.category) }" />
            <span class="event-title">{{ evt.title }}</span>
            <span class="event-badge" :style="getBadgeStyle(evt.category)">
              {{ getCategoryLabel(evt.category) }}
            </span>
          </div>
          <div v-if="evt.source === 'custom'" class="event-actions">
            <button class="edit-btn" @click="editEvent(evt)">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/>
              </svg>
            </button>
            <button class="delete-btn" @click="deleteEvent(evt)">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
              </svg>
            </button>
          </div>
        </div>

        <button class="add-day-btn" @click="startAddForDay(selectedDay.date)">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
          Agregar día propio
        </button>
      </div>
    </woot-modal>

    <!-- Modal Agregar/Editar -->
    <woot-modal v-if="showForm" :show.sync="showForm" size="small" @close="closeForm">
      <div class="event-form">
        <h3>{{ editingEvent ? 'Editar Día Propio' : 'Agregar Día Propio' }}</h3>

        <div class="form-group">
          <label>Fecha</label>
          <input v-model="formDate" type="date" min="2026-01-01" max="2026-12-31" class="form-input">
        </div>

        <div class="form-group">
          <label>Título / Descripción</label>
          <input v-model="formTitle" type="text" placeholder="Ej: Reunión de equipo..." class="form-input">
        </div>

        <div class="form-group">
          <label>Categoría</label>
          <select v-model="formCategory" class="form-input">
            <option value="custom">General (Propio)</option>
            <option value="professional">Día Profesional</option>
            <option value="religious">Religioso</option>
            <option value="cultural">Cultural</option>
            <option value="commercial">Comercial</option>
          </select>
        </div>

        <div class="form-actions">
          <div class="spacer" />
          <button class="btn-cancel" @click="closeForm">Cancelar</button>
          <button class="btn-save" :disabled="!formDate || !formTitle.trim()" @click="saveEvent">
            {{ editingEvent ? 'Guardar' : 'Agregar' }}
          </button>
        </div>
      </div>
    </woot-modal>
  </woot-modal>
</template>

<script>
import WootModal from 'dashboard/components/Modal.vue';
import axios from 'axios';

const MONTH_NAMES = [
  'Enero','Febrero','Marzo','Abril','Mayo','Junio',
  'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'
];

const WEEK_DAYS = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

const CATEGORY_MAP = {
  national:     { label: 'Feriado Nacional', color: '#EF4444', bg: 'rgba(239, 68, 68, 0.12)',    border: 'rgba(239, 68, 68, 0.25)',    text: '#FCA5A5',    priority: 1 },
  religious:    { label: 'Religioso',        color: '#F59E0B', bg: 'rgba(245, 158, 11, 0.12)',   border: 'rgba(245, 158, 11, 0.25)',   text: '#FCD34D',    priority: 2 },
  cultural:     { label: 'Cultural Peruano', color: '#8B5CF6', bg: 'rgba(139, 92, 246, 0.12)',   border: 'rgba(139, 92, 246, 0.25)',   text: '#C4B5FD',    priority: 3 },
  professional: { label: 'Día Profesional',  color: '#3B82F6', bg: 'rgba(59, 130, 246, 0.12)',   border: 'rgba(59, 130, 246, 0.25)',   text: '#93C5FD',    priority: 4 },
  commercial:   { label: 'Comercial / Cyber',color: '#EC4899', bg: 'rgba(236, 72, 153, 0.12)',   border: 'rgba(236, 72, 153, 0.25)',   text: '#F9A8D4',    priority: 5 },
  custom:       { label: 'Propio',           color: '#14B8A6', bg: 'rgba(20, 184, 166, 0.15)',   border: 'rgba(20, 184, 166, 0.25)',   text: '#5EEAD4',    priority: 6 },
};

// ✅ MISMA FUNCIÓN QUE TU CATALOGO.VUE
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
  name: 'CalendarModal',
  components: { WootModal },
  props: {
    show: { type: Boolean, default: false },
    accountId: { type: [Number, String], required: true },
  },
  data() {
    return {
      currentMonth: new Date().getMonth(),
      hoveredDay: null,
      tooltipStyle: {},
      selectedDay: null,
      showDayDetail: false,
      showForm: false,
      editingEvent: null,
      formDate: '',
      formTitle: '',
      formCategory: 'custom',
      showOnlyPropias: false,
      weekDays: WEEK_DAYS,
      monthNames: MONTH_NAMES,
      categories: CATEGORY_MAP,
      apiEvents: [],
    };
  },
  computed: {
    monthName() {
      return this.monthNames[this.currentMonth];
    },
    calendarDays() {
      const year = 2026;
      const firstDay = new Date(year, this.currentMonth, 1);
      const lastDay = new Date(year, this.currentMonth + 1, 0);
      const startDayOfWeek = firstDay.getDay();
      const daysInMonth = lastDay.getDate();
      const days = [];
      for (let i = 0; i < startDayOfWeek; i++) days.push(null);
      for (let d = 1; d <= daysInMonth; d++) {
        days.push({ date: new Date(year, this.currentMonth, d) });
      }
      return days;
    },
    activeCategories() {
      const catsInMonth = new Set();
      const year = 2026;
      const daysInMonth = new Date(year, this.currentMonth + 1, 0).getDate();
      for (let d = 1; d <= daysInMonth; d++) {
        const date = new Date(year, this.currentMonth, d);
        const ds = this.formatDateISO(date);
        this.apiEvents.forEach(e => {
          if (e.date === ds) catsInMonth.add(e.category);
        });
      }
      const result = [];
      catsInMonth.forEach(key => {
        if (this.categories[key]) {
          result.push({
            key,
            label: this.categories[key].label,
            color: this.categories[key].color,
            priority: this.categories[key].priority,
          });
        }
      });
      return result.sort((a, b) => a.priority - b.priority);
    },
  },
  watch: {
    show(val) {
      if (val) {
        this.currentMonth = new Date().getMonth();
        this.loadEvents();
      }
    },
    currentMonth() {
      this.loadEvents();
    },
  },
  mounted() {
    this.loadEvents();
  },
  methods: {
    // ✅ AHORA CON HEADERS DE AUTENTICACIÓN
    async loadEvents() {
      const year = 2026;
      const month = String(this.currentMonth + 1).padStart(2, '0');
      const startDate = `${year}-${month}-01`;
      const endDate = `${year}-${month}-31`;

      try {
        const res = await axios.get(
          `/api/v1/accounts/${this.accountId}/calendar`,
          {
            params: {
              start_date: startDate,
              end_date: endDate,
              year,
              own_only: this.showOnlyPropias,
            },
            headers: getAuthHeaders(),   // ✅ HEADERS AQUÍ
          }
        );

        this.apiEvents = res.data.map(e => ({
          id: e.id,
          date: e.date,
          title: e.name,
          category: e.event_type,
          color: e.color,
          bg: e.bg,
          border: e.border,
          text: e.text_color,
          label: e.label,
          source: e.account_id === null ? 'fixed' : 'custom',
        }));
      } catch (err) {
        console.error('Error cargando calendario:', err);
        this.apiEvents = [];
      }
    },

    getEventsForDay(date) {
      const ds = this.formatDateISO(date);
      return this.apiEvents.filter(e => e.date === ds);
    },

    formatDateISO(date) {
      const y = date.getFullYear();
      const m = String(date.getMonth() + 1).padStart(2, '0');
      const d = String(date.getDate()).padStart(2, '0');
      return `${y}-${m}-${d}`;
    },

    formatFullDate(date) {
      const days = ['Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado'];
      return `${days[date.getDay()]}, ${this.monthNames[date.getMonth()]} ${String(date.getDate()).padStart(2,'0')}, 2026`;
    },

    getCategoryColor(category) {
      return this.categories[category]?.color || '#14B8A6';
    },

    getCategoryLabel(category) {
      return this.categories[category]?.label || 'Evento';
    },

    getBadgeStyle(category) {
      const cat = this.categories[category];
      if (!cat) return {};
      return { background: cat.bg, color: cat.text };
    },

    getCardStyle(category) {
      const cat = this.categories[category];
      if (!cat) return {};
      return { background: cat.bg, borderColor: cat.border };
    },

    dayCellClasses(day) {
      if (!day) return 'day-empty';
      const events = this.getEventsForDay(day.date);
      const isToday = this.formatDateISO(day.date) === this.formatDateISO(new Date());
      const classes = ['day-cell'];

      if (events.length === 0) {
        classes.push('day-normal');
      } else {
        const hasCustom = events.some(e => e.category === 'custom');
        if (hasCustom) {
          classes.push('day-propia');
        } else {
          const sorted = events.map(e => ({
            category: e.category,
            priority: this.categories[e.category]?.priority || 99,
          })).sort((a, b) => a.priority - b.priority);
          classes.push(`day-cat-${sorted[0].category}`);
        }
      }

      if (isToday) classes.push('day-today');
      return classes;
    },

    prevMonth() { if (this.currentMonth > 0) this.currentMonth--; },
    nextMonth() { if (this.currentMonth < 11) this.currentMonth++; },

    onDayHover(day, event) {
      if (!day || this.getEventsForDay(day.date).length === 0) {
        this.hoveredDay = null;
        return;
      }
      this.hoveredDay = day;
      const rect = event.target.getBoundingClientRect();
      const tooltipWidth = 240;
      const tooltipHeight = 120;
      const padding = 12;
      let left = rect.left + rect.width / 2 - tooltipWidth / 2;
      let top = rect.top - tooltipHeight - padding;
      if (left < padding) left = padding;
      if (left + tooltipWidth > window.innerWidth - padding) left = window.innerWidth - tooltipWidth - padding;
      if (top < padding) top = rect.bottom + padding;
      this.tooltipStyle = { position: 'fixed', left: `${left}px`, top: `${top}px`, zIndex: 9999 };
    },

    onDayClick(day) {
      this.selectedDay = day;
      this.showDayDetail = true;
    },

    openAddModal() {
      this.editingEvent = null;
      this.formDate = this.formatDateISO(new Date());
      this.formTitle = '';
      this.formCategory = 'custom';
      this.showForm = true;
    },

    startAddForDay(date) {
      this.showDayDetail = false;
      this.editingEvent = null;
      this.formDate = this.formatDateISO(date);
      this.formTitle = '';
      this.formCategory = 'custom';
      this.showForm = true;
    },

    editEvent(evt) {
      this.showDayDetail = false;
      this.editingEvent = evt;
      this.formDate = evt.date;
      this.formTitle = evt.title;
      this.formCategory = evt.category || 'custom';
      this.showForm = true;
    },

    // ✅ AHORA CON HEADERS DE AUTENTICACIÓN
    async saveEvent() {
      if (!this.formDate || !this.formTitle.trim()) return;

      const payload = {
        date: this.formDate,
        name: this.formTitle.trim(),
        event_type: this.formCategory,
        color: this.getCategoryColor(this.formCategory),
      };

      try {
        if (this.editingEvent && this.editingEvent.source === 'custom') {
          await axios.put(
            `/api/v1/accounts/${this.accountId}/calendar/${this.editingEvent.id}`,
            { calendar_event: payload },
            { headers: getAuthHeaders() }   // ✅ HEADERS AQUÍ
          );
        } else {
          await axios.post(
            `/api/v1/accounts/${this.accountId}/calendar`,
            { calendar_event: payload },
            { headers: getAuthHeaders() }   // ✅ HEADERS AQUÍ
          );
        }
        this.closeForm();
        await this.loadEvents();
      } catch (err) {
        console.error('Error guardando evento:', err);
        alert('Error al guardar');
      }
    },

    // ✅ AHORA CON HEADERS DE AUTENTICACIÓN
    async deleteEvent(evt) {
      if (!confirm(`¿Eliminar "${evt.title}"?`)) return;
      try {
        await axios.delete(
          `/api/v1/accounts/${this.accountId}/calendar/${evt.id}`,
          { headers: getAuthHeaders() }   // ✅ HEADERS AQUÍ
        );
        await this.loadEvents();
        if (this.selectedDay && this.getEventsForDay(this.selectedDay.date).length === 0) {
          this.selectedDay = null;
          this.showDayDetail = false;
        }
      } catch (err) {
        console.error('Error eliminando:', err);
      }
    },

    closeForm() {
      this.showForm = false;
      this.editingEvent = null;
      this.formDate = '';
      this.formTitle = '';
      this.formCategory = 'custom';
    },

    onClose() {
      this.$emit('close');
    },
  },
};
</script>

<style lang="scss" scoped>
.calendar-modal { padding: 0; background: #151718; border-radius: 12px; min-width: 380px; position: relative; }
.calendar-header { display: flex; align-items: center; justify-content: center; padding: 16px 20px; border-bottom: 1px solid #2A2E33; }
.calendar-nav { display: flex; align-items: center; gap: 12px; }
.nav-btn { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; border-radius: 8px; background: transparent; border: none; color: #9CA3AF; cursor: pointer; transition: all 0.2s;
  &:hover:not(:disabled) { background: #252830; color: #fff; }
  &:disabled { opacity: 0.3; cursor: not-allowed; }
}
.month-title { font-size: 16px; font-weight: 700; color: #fff; text-transform: uppercase; letter-spacing: 0.05em; min-width: 140px; text-align: center; }
.calendar-filter { padding: 12px 20px; border-bottom: 1px solid #2A2E33; }
.filter-toggle { display: flex; align-items: center; gap: 10px; cursor: pointer; user-select: none;
  input { display: none; }
}
.toggle-slider { width: 36px; height: 20px; background: #2A2E33; border-radius: 10px; position: relative; transition: background 0.2s;
  &::after { content: ''; position: absolute; top: 2px; left: 2px; width: 16px; height: 16px; background: #9CA3AF; border-radius: 50%; transition: all 0.2s; }
}
.filter-toggle input:checked + .toggle-slider { background: rgba(20, 184, 166, 0.3);
  &::after { left: 18px; background: #14B8A6; }
}
.toggle-label { font-size: 12px; color: #9CA3AF; }
.weekdays-grid { display: grid; grid-template-columns: repeat(7, 1fr); padding: 16px 16px 8px; gap: 4px; }
.weekday-label { text-align: center; font-size: 11px; font-weight: 600; color: #6B7280; text-transform: uppercase; letter-spacing: 0.05em; padding: 8px 0; }
.days-grid { display: grid; grid-template-columns: repeat(7, 1fr); padding: 0 16px 16px; gap: 4px; }
.day-cell { position: relative; height: 40px; display: flex; flex-direction: column; align-items: center; justify-content: center; font-size: 13px; border-radius: 8px; cursor: pointer; transition: all 0.15s ease;
  &.day-empty { cursor: default; }
  &.day-normal { color: #D1D5DB; &:hover { background: #252830; } }
  &.day-cat-national { background: rgba(239, 68, 68, 0.12); color: #FCA5A5; border: 1px solid rgba(239, 68, 68, 0.2); font-weight: 500; &:hover { background: rgba(239, 68, 68, 0.2); } }
  &.day-cat-religious { background: rgba(245, 158, 11, 0.12); color: #FCD34D; border: 1px solid rgba(245, 158, 11, 0.2); font-weight: 500; &:hover { background: rgba(245, 158, 11, 0.2); } }
  &.day-cat-cultural { background: rgba(139, 92, 246, 0.12); color: #C4B5FD; border: 1px solid rgba(139, 92, 246, 0.2); font-weight: 500; &:hover { background: rgba(139, 92, 246, 0.2); } }
  &.day-cat-professional { background: rgba(59, 130, 246, 0.12); color: #93C5FD; border: 1px solid rgba(59, 130, 246, 0.2); font-weight: 500; &:hover { background: rgba(59, 130, 246, 0.2); } }
  &.day-cat-commercial { background: rgba(236, 72, 153, 0.12); color: #F9A8D4; border: 1px solid rgba(236, 72, 153, 0.2); font-weight: 500; &:hover { background: rgba(236, 72, 153, 0.2); } }
  &.day-propia { background: rgba(20, 184, 166, 0.15); color: #5EEAD4; border: 1px solid rgba(20, 184, 166, 0.3); font-weight: 600; &:hover { background: rgba(20, 184, 166, 0.25); } }
  &.day-today { box-shadow: inset 0 0 0 1.5px rgba(20, 184, 166, 0.6); }
}
.day-number { line-height: 1; }
.event-dots { position: absolute; bottom: 4px; display: flex; gap: 2px; }
.event-dot { width: 4px; height: 4px; border-radius: 50%; }
.day-tooltip { width: 240px; background: #1C1E23; border: 1px solid #2A2E33; border-radius: 10px; padding: 12px; box-shadow: 0 10px 40px rgba(0, 0, 0, 0.6); pointer-events: none; }
.tooltip-date { font-size: 11px; color: #9CA3AF; margin-bottom: 8px; font-weight: 500; }
.tooltip-event { display: flex; align-items: center; gap: 8px; margin-bottom: 6px; &:last-child { margin-bottom: 0; } }
.tooltip-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }
.tooltip-title { font-size: 13px; color: #fff; flex: 1; }
.tooltip-badge { font-size: 9px; font-weight: 700; padding: 2px 6px; border-radius: 4px; text-transform: uppercase; letter-spacing: 0.03em; flex-shrink: 0; }
.tooltip-arrow { position: absolute; bottom: -5px; left: 50%; transform: translateX(-50%) rotate(45deg); width: 10px; height: 10px; background: #1C1E23; border-right: 1px solid #2A2E33; border-bottom: 1px solid #2A2E33; }
.calendar-footer { display: flex; align-items: center; justify-content: space-between; padding: 12px 20px; border-top: 1px solid #2A2E33; }
.legend { display: flex; flex-wrap: wrap; gap: 10px; max-width: 280px; }
.legend-item { display: flex; align-items: center; gap: 5px; }
.legend-dot { width: 7px; height: 7px; border-radius: 50%; }
.legend-text { font-size: 10px; color: #9CA3AF; }
.add-btn { display: flex; align-items: center; gap: 6px; font-size: 12px; font-weight: 600; color: #14B8A6; background: transparent; border: none; cursor: pointer; transition: color 0.2s; flex-shrink: 0; &:hover { color: #5EEAD4; } }
.day-detail { padding: 20px; background: #151718; border-radius: 12px; }
.day-detail-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; h3 { font-size: 16px; font-weight: 700; color: #fff; } }
.empty-state { text-align: center; color: #6B7280; font-size: 14px; padding: 24px 0; }
.event-card { display: flex; align-items: center; justify-content: space-between; padding: 12px; border-radius: 8px; margin-bottom: 8px; border: 1px solid transparent; }
.event-info { display: flex; align-items: center; gap: 10px; }
.event-dot-lg { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.event-title { font-size: 14px; color: #fff; }
.event-badge { font-size: 10px; font-weight: 700; padding: 2px 8px; border-radius: 4px; text-transform: uppercase; flex-shrink: 0; }
.event-actions { display: flex; gap: 4px; }
.edit-btn, .delete-btn { width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; border-radius: 6px; background: transparent; border: none; color: #9CA3AF; cursor: pointer; transition: all 0.2s; }
.edit-btn:hover { color: #14B8A6; background: rgba(20, 184, 166, 0.1); }
.delete-btn:hover { color: #EF4444; background: rgba(239, 68, 68, 0.1); }
.add-day-btn { width: 100%; margin-top: 12px; padding: 10px; border-radius: 8px; border: 1px dashed #2A2E33; background: transparent; color: #9CA3AF; font-size: 13px; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 6px; transition: all 0.2s; &:hover { color: #14B8A6; border-color: rgba(20, 184, 166, 0.3); } }
.event-form { padding: 20px; background: #151718; border-radius: 12px; h3 { font-size: 16px; font-weight: 700; color: #fff; margin-bottom: 16px; } }
.form-group { margin-bottom: 14px; label { display: block; font-size: 12px; color: #9CA3AF; margin-bottom: 6px; font-weight: 500; } }
.form-input { width: 100%; background: #1C1E23; border: 1px solid #2A2E33; border-radius: 8px; padding: 10px 12px; color: #fff; font-size: 14px; transition: border-color 0.2s; &:focus { outline: none; border-color: #14B8A6; } &::placeholder { color: #4B5563; } option { background: #1C1E23; color: #fff; } }
.form-actions { display: flex; align-items: center; gap: 8px; margin-top: 20px; }
.spacer { flex: 1; }
.btn-cancel { padding: 8px 14px; border-radius: 8px; font-size: 13px; font-weight: 500; color: #9CA3AF; background: transparent; border: none; cursor: pointer; transition: color 0.2s; &:hover { color: #fff; } }
.btn-save { padding: 8px 16px; border-radius: 8px; font-size: 13px; font-weight: 700; color: #000; background: #14B8A6; border: none; cursor: pointer; transition: background 0.2s; &:hover:not(:disabled) { background: #5EEAD4; } &:disabled { opacity: 0.4; cursor: not-allowed; } }
</style>
