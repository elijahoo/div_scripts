class RelationKartei < Kartei::


def insert_kk(ft, pt)
  zuord = Kartei::SqlZuord.new
  zuord.pktabname = ft
  zuord.pkcolname ="#{pt}_id"
  zuord.fktabname = pt
  zuord.fkcolname = "id"
  zuord.matchopt = "NONE"
end
