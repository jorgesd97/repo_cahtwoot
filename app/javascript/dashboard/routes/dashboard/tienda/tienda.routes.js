import { frontendURL } from '../../../helper/URLHelper';
import TiendaLayout from './TiendaLayout.vue';
import Catalogo from './Catalogo.vue';
import Ordenes from './Ordenes.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/tienda'),
      component: TiendaLayout,
      redirect: { name: 'tienda_catalogo' },
      children: [
        {
          path: 'catalogo',
          name: 'tienda_catalogo',
          component: Catalogo,
          meta: { permissions: ['administrator', 'agent'] },
        },
        {
          path: 'ordenes',
          name: 'tienda_ordenes',
          component: Ordenes,
          meta: { permissions: ['administrator', 'agent'] },
        },
      ],
    },
  ],
};