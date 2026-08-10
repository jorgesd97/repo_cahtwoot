import { frontendURL } from '../../../helper/URLHelper';

const Catalogo = () => import('./Catalogo.vue');

export default {
  routes: [
    {
      path: frontendURL('/accounts/:accountId/tienda/catalogo'),
      name: 'tienda_catalogo',
      component: Catalogo,
      meta: {
        permissions: ['administrator', 'agent'],
      },
    },
  ],
};