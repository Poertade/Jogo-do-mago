class_name EnemyData
extends ScannableData
## Um tipo de inimigo. Herda de ScannableData: todo inimigo pode ser escaneado pela Lente
## e tem aspectos. Cada inimigo é um arquivo em data/enemies/.
## Os valores padrão aqui são zero de propósito: os valores reais ficam no arquivo de dados.

## Cena com o corpo do inimigo (scenes/enemies/), que usa o script Enemy.
@export_file("*.tscn") var scene_path: String

@export_group("Combate")
@export var max_health: float = 0.0
## Dano de cada golpe no jogador.
@export var damage: float = 0.0
## Multiplicador de dano por elemento (ex.: fire = 1.5 → fogo causa 50% a mais).
@export var weaknesses: Dictionary[StringName, float] = {}

@export_group("Comportamento")
## Velocidade perseguindo, em metros por segundo.
@export var move_speed: float = 0.0
## Distância em que nota o jogador (se o enxergar).
@export var sight_range: float = 0.0
## Distância de onde consegue golpear.
@export var attack_range: float = 0.0
## Segundos entre começar o golpe e ele acertar (o jogador pode se afastar).
@export var attack_windup: float = 0.0
## Segundos entre um golpe e o próximo.
@export var attack_cooldown: float = 0.0
## Segundos parado depois de tomar dano (a "reação ao dano"). 0: não se abala (chefes).
@export var hurt_stun: float = 0.0

@export_group("Espólio")
## Prata que o inimigo deixa ao ser derrotado (sorteada entre os dois valores).
@export var silver_min: int = 0
@export var silver_max: int = 0
## Material que o inimigo pode deixar (data/items/), a chance e quanto.
@export var material: StringName
@export_range(0.0, 1.0) var material_chance: float = 0.0
@export var material_amount: int = 0
## Ligado: o material vai direto para a escola, sem risco de se perder (raridades de chefes,
## que não voltam).
@export var material_safe := false

@export_group("Chefe")
## Mostra a barra de vida no alto da tela quando o inimigo nota o jogador.
@export var show_health_bar := false
## Fração da vida em que o inimigo se enfurece (0 = nunca; 0,5 = na metade da vida).
@export var enrage_at: float = 0.0
## Enfurecido: anda e golpeia mais rápido (multiplica a velocidade e divide a preparação e o
## intervalo dos golpes).
@export var enrage_speed: float = 1.0
## Inimigos que ele chama ao se enfurecer (aparecem em volta dele).
@export var enrage_summons: Array[EnemyData] = []
## Aviso mostrado ao se enfurecer (chave de locales/content.csv).
@export var enrage_message_key: String
