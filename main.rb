require 'json'

data = JSON.parse(File.open('data.json').read)

queued_orders = data["queued_orders"]
users         = data["users"]
@users_by_id   = users.map { |user| [user["id"], user]}.to_h
out_queued_orders = []
out_orders        = []

def self.user_buy(queued_order)
  user_id                           = queued_order['user_id']
  btc_amount                        = queued_order['btc_amount']
  price								= queued_order['price']
  @users_by_id[user_id]['btc_balance'] += "#{btc_sign(queued_order['direction'])}#{btc_amount}".to_i
  @users_by_id[user_id]['eur_balance'] -= "#{btc_sign(queued_order['direction'])}#{btc_amount * price}".to_i
end

def self.btc_sign(direction)
  direction == 'buy' ? '+' : '-'
end


grouped_orders = queued_orders.group_by { |order| "#{order['btc_amount']}--#{order['price']}" }

grouped_orders.values.each do |orders|
  if orders.count > 1
    g_direction_orders = orders.group_by {|order| order["direction"]}
    buy_orders    = g_direction_orders["buy"].sort_by { |hsh| hsh["id"] }
    sell_orders   = g_direction_orders["sell"].sort_by { |hsh| hsh["id"] }
    nbr_of_orders = [buy_orders.count, sell_orders.count].min
    
    # les bonne commandes
    buy_orders  = buy_orders.first(nbr_of_orders)
    sell_orders = sell_orders.first(nbr_of_orders)
    out_orders += (buy_orders + sell_orders).each do |order|
    	user_buy(order)
    	order["state"] = "executed"
    end

  else
    out_queued_orders << orders.first
  end
end

out_data = {
	"users":         @users_by_id.values,
	"queued_orders": out_queued_orders,
	"orders":        out_orders
}


output_file = File.open('output.json', 'w')
output_file.write(out_data)