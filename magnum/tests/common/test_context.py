#    Copyright 2015 OpenStack Foundation
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

from magnum.common import context
from magnum.tests import base


class ContextTestCase(base.TestCase):

    def _create_context(self):
        return context.RequestContext(auth_token='auth_token1',
                                      auth_url='auth_url1',
                                      domain_id='domain_id1',
                                      domain_name='domain_name1',
                                      user='user1',
                                      user_id='user-id1',
                                      project='tenant1',
                                      project_id='tenant-id1',
                                      is_admin=True,
                                      is_public_api=True,
                                      read_only=True,
                                      show_deleted=True,
                                      request_id='request_id1',
                                      trust_id='trust_id1',
                                      auth_token_info='auth_token_info1')

    def test_context(self):
        ctx = self._create_context()

        self.assertEqual("auth_token1", ctx.auth_token)
        self.assertEqual("auth_url1", ctx.auth_url)
        self.assertEqual("domain_id1", ctx.domain_id)
        self.assertEqual("domain_name1", ctx.domain_name)
        self.assertEqual("user1", ctx.user)
        self.assertEqual("user-id1", ctx.user_id)
        self.assertEqual("tenant1", ctx.project)
        self.assertEqual("tenant-id1", ctx.project_id)
        self.assertTrue(ctx.is_admin)
        self.assertTrue(ctx.is_public_api)
        self.assertTrue(ctx.read_only)
        self.assertTrue(ctx.show_deleted)
        self.assertEqual("request_id1", ctx.request_id)
        self.assertEqual("trust_id1", ctx.trust_id)
        self.assertEqual("auth_token_info1", ctx.auth_token_info)

    def test_to_dict_from_dict(self):
        ctx = self._create_context()
        ctx2 = context.RequestContext.from_dict(ctx.to_dict())

        self.assertEqual(ctx.auth_token, ctx2.auth_token)
        self.assertEqual(ctx.auth_url, ctx2.auth_url)
        self.assertEqual(ctx.domain_id, ctx2.domain_id)
        self.assertEqual(ctx.domain_name, ctx2.domain_name)
        self.assertEqual(ctx.user, ctx2.user)
        self.assertEqual(ctx.user_id, ctx2.user_id)
        self.assertEqual(ctx.tenant, ctx2.tenant)
        self.assertEqual(ctx.project, ctx2.project)
        self.assertEqual(ctx.project_id, ctx2.project_id)
        self.assertEqual(ctx.is_admin, ctx2.is_admin)
        self.assertEqual(ctx.is_public_api, ctx2.is_public_api)
        self.assertEqual(ctx.read_only, ctx2.read_only)
        self.assertEqual(ctx.show_deleted, ctx2.show_deleted)
        self.assertEqual(ctx.request_id, ctx2.request_id)
        self.assertEqual(ctx.trust_id, ctx2.trust_id)
        self.assertEqual(ctx.auth_token_info, ctx2.auth_token_info)
