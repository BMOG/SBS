namespace :db do
  desc "Fill database with initial data"
  task populate: :environment do
    admin = User.create!(name: "rostopchine",
                         email: "brian75013@hotmail.fr",
                         password: "br99ni75",
                         password_confirmation: "br99ni75")
    admin.toggle!(:admin)
    admin = User.create!(name: "korrigan",
                         email: "gilles.ovibos@orange.fr",
                         password: "korrigan",
                         password_confirmation: "korrigan")
    admin.toggle!(:admin)
    admin = User.create!(name: "galileo",
                         email: "olivv2000@yahoo.fr",
                         password: "galileo",
                         password_confirmation: "galileo")
    admin.toggle!(:admin)
    
    parm = Parameter.create!
  end
end