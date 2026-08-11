import { frontendURL } from '../../../helper/URLHelper';
import Catalogo from './Catalogo.vue';
import Ordenes from './Ordenes.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/tienda/catalogo'),
      name: 'tienda_catalogo',
      component: Catalogo,
      meta: {
        permissions: ['administrator', 'agent'],
      },
    },
    {
      path: frontendURL('accounts/:accountId/tienda/ordenes'),
      name: 'tienda_ordenes',
      component: Ordenes,
      meta: {
        permissions: ['administrator', 'agent'],
      },
    },
  ],
};