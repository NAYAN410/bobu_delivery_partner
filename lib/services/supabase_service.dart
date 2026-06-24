import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getProfile(String id) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', id)
        .single();
    return response;
  }

  Stream<List<Map<String, dynamic>>> getAssignedOrders(String riderId) {
    return client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('delivery_partner_id', riderId)
        .order('id', ascending: false);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await client.from('orders').update({'status': status}).eq('id', orderId);
  }

  Future<void> verifyPinAndDeliver(String orderId, String pin) async {
    await client.rpc(
      'secure_verify_delivery',
      params: {
        'p_order_id': orderId,
        'p_entered_pin': pin,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final response = await client
        .from('order_items')
        .select('*, pizzas(name)')
        .eq('order_id', orderId);
    return List<Map<String, dynamic>>.from(response);
  }
}
