export default ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 1337),
  app: {
    keys: env.array('APP_KEYS'),
  },
  url: env('PUBLIC_URL', 'http://localhost:1337'),
  proxy: true,
  admin: {
    url: '/admin',
    auth: {
      secret: env('ADMIN_JWT_SECRET'),
      options: {
        expiresIn: '7d',
      },
      sessions: {
        cookieOptions: {
          secure: env.bool('ADMIN_COOKIE_SECURE', false),
          httpOnly: true,
          sameSite: 'lax',
        },
      },
    },
  },
});
