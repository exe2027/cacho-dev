// TableLayout.cs — CACHO Unity, ETAPA 1 (solo mesa + assets).
//
// Posiciona la mesa horizontal 16:9 a partir de las posiciones medidas
// sobre el mockup (centros en % de ancho/alto de pantalla) y de la
// geometría Flutter vigente (sketch_layout.dart: tableTop 56,
// consoleH 72, tableW = screenW - 32, en referencia 844x390).
//
// ALCANCE: solo definición visual. Sin gameplay, sin reglas, sin
// animaciones de juego, sin red, sin bots. El botón VER es un marcador
// visual sin lógica: en esta etapa no revela nada.
//
// DECISIONES DE PARIDAD APLICADAS (docs/19, 26-oct-2026 07:32, 07:40, 07:43;
// corrección del usuario 09:35: "me equivoqué eran 6"):
//   - N1 CORREGIDO 09:35: partidas de 2 a 6 jugadores. MaxSeats = 6. NUNCA más.
//     (docs/19 N1 todavía dice 2 a 5: quedó desactualizado; la corrección 09:35 manda
//     y su actualización en docs/19 queda en manos de la coordinación, no de aquí.)
//   - N2: los puestos vacíos quedan LIBRES (no se rellenan por defecto
//     con bots en la mesa). Los asientos inactivos muestran el marcador
//     de puesto libre, sin avatar ni vaso.
//   - V1: mis dados van OCULTOS bajo mi vaso; solo se ven con VER.
//   - V2 ACTUALIZADA (B6, 07:40): los dados del centro existen visibles en
//     CUALQUIER estado de revelación (Dudo, Calzo, duda de Paso, Kamikaze).
//     En esta etapa, sin lógica de juego, el grupo CenterDiceGroup nace OCULTO.
//     REVELACIÓN LEGIBLE (09:35): ningún dado mostrado puede ser pequeño e
//     ilegible; todo dado visible se lee a tamaño real, sin solapes, con los
//     que cuentan destacados uno a uno. NUNCA una revelación con todas las
//     manos en pequeño al centro.
//   - V3: cada jugador ve solo su vista (aquí solo se define la vista
//     propia; no hay vistas rivales ni red).
//   - B5 (07:40): agitar LANZA los dados; VER los mira. Ambos quedan.
//   - C8 (07:40) + corrección 09:35: barra superior por ahora solo fichas,
//     ajustes y menú, MÁS micrófono (voz) y música/DJ, que SE MANTIENEN y no se
//     diseñan fuera. Regalo/misiones/amigos solo cuando existan sus funciones.
//   - C9 (07:40): chat de TEXTO fuera; reacciones rápidas (emotes) se quedan
//     (slot en consola, animación en etapa posterior).
//
// PENDIENTE, NO RESUELTO AQUÍ:
//   - La alineación Flutter 8 -> 6 (motor, servidor, lobby, selector
//     de bots, tests) queda ENCOLADA para el pase posterior al frente
//     horizontal. Este script NO la implementa ni la da por hecha.
//   - Tiers de lobby con nombres nuevos C7, revelación en duda de Paso /
//     Kamikaze en detalle, y resto de P1–P21: ver PARIDAD.md.
//   - Los glTF de Blender van en los slots de ASSETS_NEEDED.md; donde
//     falta un asset, el campo queda sin asignar y el script avisa
//     sin romper (TODO en cada campo).
//
// APIs usadas: solo UnityEngine y UnityEngine.UI. Nada de DOTween,
// Cinemachine, Timeline ni paquetes externos en esta etapa.

using UnityEngine;
using UnityEngine.UI;

public class TableLayout : MonoBehaviour
{
    // ------------------------------------------------------------------
    // Constantes de color (identidad casino Flutter vigente).
    // Valores 0-1 = byte / 255, redondeados a 3 decimales.
    // ------------------------------------------------------------------

    // Dorado mate (CachoColors.gold en Flutter, theme.dart).
    public static readonly Color MatteGold = new Color(0.788f, 0.635f, 0.294f); // 0xC9A24B
    public static readonly Color Ivory = new Color(0.961f, 0.937f, 0.855f);      // marfil de acentos
    // Paño carbón: tier Casino 500, DEFINITIVO (table_themes.dart).
    public static readonly Color FeltCharcoalCenter = new Color(0.090f, 0.090f, 0.090f); // 0x171717
    public static readonly Color FeltCharcoalEdge = new Color(0.047f, 0.047f, 0.047f);   // 0x0C0C0C
    // Paños por tier Flutter vigentes (propuestas salvo Casino 500).
    public static readonly Color FeltBarrioCenter = new Color(0.043f, 0.365f, 0.231f);   // 0x0B5D3B verde
    public static readonly Color FeltSalonCenter = new Color(0.078f, 0.196f, 0.290f);    // 0x14324A azul
    public static readonly Color FeltVipCenter = new Color(0.180f, 0.106f, 0.227f);      // 0x2E1B3A morado
    public static readonly Color FeltHighRollerCenter = new Color(0.290f, 0.208f, 0.071f); // 0x4A3512 bronce
    // Madera oscura del borde (table_themes.dart, marco).
    public static readonly Color WoodDark = new Color(0.165f, 0.102f, 0.055f); // 0x2A1A0E
    // Consola inferior (sprites Flutter btn_*.png; color de respaldo si
    // el sprite falta: el botón se tiñe con el color, nunca se dibuja
    // un sustituto de código como diseño final).
    public static readonly Color CalzoGreen = new Color(0.055f, 0.478f, 0.310f); // 0x0E7A4F
    public static readonly Color DudoRed = new Color(0.702f, 0.125f, 0.165f);    // 0xB3202A
    public static readonly Color PasoBlueGrey = new Color(0.078f, 0.345f, 0.420f); // 0x14586B
    public static readonly Color TurnGreen = new Color(0.200f, 0.700f, 0.300f);  // aro de turno (semáforo, respaldo)

    // ------------------------------------------------------------------
    // Posiciones medidas sobre el mockup (centros, % ancho / % alto,
    // medidos desde ARRIBA-IZQUIERDA, como en Flutter).
    // En UI de Unity el ancla Y se mide desde ABAJO: la conversión
    // (1 - y) vive en Place() y solo ahí.
    // ------------------------------------------------------------------

    // Pozo arriba al centro, EN PILA con el asiento superior-central
    // (corrección 09:35: 6 asientos; la columna superior apila, sin solapes:
    // avatar superior-central -> su placa -> placa del pozo -> vaso de la
    // columna. La medición mockup original (placa 50/6, vaso 51/21) era la
    // columna superior ANTES del 6º asiento; los valores de abajo son
    // PROVISIONALES y manda la medición de cajas del render Blender, que
    // debe dar CERO solapes o informar el solape medido).
    public static readonly Vector2 PotPlate = new Vector2(0.50f, 0.21f);
    public static readonly Vector2 PotCup = new Vector2(0.50f, 0.29f); // vaso de la columna superior

    // Asientos (6 como máximo, N1 corregido 09:35). Orden fijo:
    // superior-central + 4 rivales + yo.
    public static readonly Vector2 SeatTopCenter = new Vector2(0.50f, 0.10f);
    public static readonly Vector2 SeatTopLeft = new Vector2(0.13f, 0.16f);
    public static readonly Vector2 SeatTopRight = new Vector2(0.87f, 0.16f);
    public static readonly Vector2 SeatMidLeft = new Vector2(0.17f, 0.49f);
    public static readonly Vector2 SeatMidRight = new Vector2(0.87f, 0.49f);
    public static readonly Vector2 SeatMe = new Vector2(0.50f, 0.60f);

    // Vasos rivales (centros %; mi vaso va delante de mi asiento, más
    // grande — docs/18 §2 — y es objeto levantable, ver Mesa.unity.txt).
    public static readonly Vector2 CupTopCenter = new Vector2(0.50f, 0.29f);
    public static readonly Vector2 CupTopLeft = new Vector2(0.26f, 0.24f);
    public static readonly Vector2 CupTopRight = new Vector2(0.74f, 0.24f);
    public static readonly Vector2 CupMidLeft = new Vector2(0.23f, 0.53f);
    public static readonly Vector2 CupMidRight = new Vector2(0.78f, 0.53f);

    // Consola inferior (y = 0.88 desde arriba; centros X %).
    // ChatX pasó a ser el slot de reacciones/emotes (C9: chat de texto
    // fuera, emotes se quedan).
    public const float ConsoleYFromTop = 0.88f;
    public const float EmotesX = 0.08f;
    public const float Tile1X = 0.18f;
    public const float Tile6X = 0.48f;
    public const float CalzoX = 0.61f;
    public const float DudoX = 0.77f;
    public const float PasoX = 0.90f;

    // Geometría Flutter de referencia (sketch_layout.dart).
    public const float TableTopPx = 56f;   // tableTop
    public const float ConsoleHPx = 72f;   // consoleH
    public const float TableMarginPx = 32f; // tableW = screenW - 32

    // ------------------------------------------------------------------
    // Referencias de escena (asignar en el inspector; TODO = slot de
    // ASSETS_NEEDED.md). Todo se comprueba por null: un slot vacío
    // avisa y se salta, nunca rompe la escena.
    // ------------------------------------------------------------------

    [Header("Estructura UI")]
    [SerializeField] private RectTransform canvas;
    [SerializeField] private RectTransform topBar;          // Barra superior (solo datos reales; ver PARIDAD.md)
    [SerializeField] private RectTransform tableArea;       // Óvalo/mesa (slot: mesa glTF o mesa_fondo.jpg temporal)
    [SerializeField] private RectTransform bottomConsole;   // Consola APOSTAR 1-6 + CALZO/DUDO/PASO
    [SerializeField] private RectTransform pasoChallengeBar; // Banda de desafío de Paso (P10; marcador visual, sin lógica)

    [Header("Pozo")]
    [SerializeField] private RectTransform potPlate; // Placa "POZO + monto" (monto real; sin lógica en etapa 1)
    [SerializeField] private RectTransform potCup;   // Vaso del pozo (slot glTF vaso; TODO)

    [Header("Asientos: 6 como máximo (N1 corregido 09:35), en orden TC, TL, TR, ML, MR, YO")]
    [SerializeField] private RectTransform[] seatAnchors = new RectTransform[6];
    [SerializeField] private RectTransform[] cupAnchors = new RectTransform[5]; // solo rivales; mi vaso va aparte
    [SerializeField] private RectTransform myCup;        // Mi vaso, más grande, objeto levantable (TODO glTF vaso_cuero)
    [SerializeField] private RectTransform myDiceHidden; // Mis dados OCULTOS bajo mi vaso (V1; nacen inactivos a la vista)
    [SerializeField] private RectTransform centerDiceGroup; // Dados del centro: OCULTOS salvo revelación (V2)
    [SerializeField] private RectTransform verButton;    // Botón/área VER: marcador visual SIN lógica (V1)

    [Header("Prefabs por nombre (slots; TODO si el asset no existe aún)")]
    [SerializeField] private GameObject seatPrefab;      // TODO: prefab asiento (avatar + placa + aro)
    [SerializeField] private GameObject cupPrefab;       // TODO: prefab vaso de cuero glTF + posavasos
    [SerializeField] private GameObject diePrefab;       // TODO: prefab dado glTF (6 caras)
    [SerializeField] private GameObject freeSeatMarker;  // Marcador de puesto LIBRE (N2; sin avatar, sin vaso)

    [Header("Partida (visual, sin lógica)")]
    [Range(2, 6)] public int seatCount = 6; // N1 corregido 09:35: de 2 a 6. Fuera de rango se limita en Awake.
    public int stakeTier = 500; // Tier visual por defecto: El Casino 500 (paño carbón definitivo).

    private static readonly Vector2[] SeatPositions =
    {
        SeatTopCenter, SeatTopLeft, SeatTopRight, SeatMidLeft, SeatMidRight, SeatMe
    };

    private static readonly Vector2[] CupPositions =
    {
        CupTopCenter, CupTopLeft, CupTopRight, CupMidLeft, CupMidRight
    };

    private void Awake()
    {
        // N1 corregido 09:35: nunca más de 6 asientos, nunca menos de 2.
        seatCount = Mathf.Clamp(seatCount, 2, 6);
        LayoutTable();
        ApplyTierFelt(stakeTier);
        ApplyHiddenDiceState();
    }

    // Posiciona toda la mesa desde las constantes %. Se puede volver a
    // llamar tras un cambio de orientación; no crea objetos ni lógica.
    public void LayoutTable()
    {
        // Barra superior: banda completa arriba (Flutter: 56 px).
        PlaceFullWidth(topBar, 0f, 1f, TableTopPx, fromTop: true);
        // Mesa: márgenes laterales Flutter (tableW = screenW - 32).
        Place(tableArea, new Vector2(0.50f, 0.50f), new Vector2(0.96f, 0.76f));
        // Consola inferior: banda completa abajo (Flutter: 72 px).
        PlaceFullWidth(bottomConsole, 0f, 0f, ConsoleHPx, fromTop: false);
        // Banda de desafío de Paso: justo sobre la consola, oculta en
        // etapa 1 (no hay Paso que desafiar sin lógica de juego).
        if (pasoChallengeBar != null)
        {
            PlaceFullWidth(pasoChallengeBar, 0f, 0f, 40f, fromTop: false);
            pasoChallengeBar.gameObject.SetActive(false);
        }

        Place(potPlate, PotPlate, new Vector2(0.16f, 0.09f));
        Place(potCup, PotCup, new Vector2(0.07f, 0.12f));

        // Asientos: los activos se posicionan; los inactivos quedan
        // LIBRES (N2): sin avatar ni vaso, solo el marcador de puesto
        // libre si está asignado. No se rellenan con bots por defecto.
        for (int i = 0; i < SeatPositions.Length; i++)
        {
            bool active = i < seatCount;
            if (seatAnchors != null && i < seatAnchors.Length)
            {
                if (seatAnchors[i] != null)
                {
                    seatAnchors[i].gameObject.SetActive(active);
                    if (active) Place(seatAnchors[i], SeatPositions[i], new Vector2(0.09f, 0.15f));
                }
                else if (!active && freeSeatMarker != null)
                {
                    Debug.LogWarning("[TableLayout] Asiento " + i + " sin asignar; puesto libre sin marcador.");
                }
            }
            if (i < CupPositions.Length && cupAnchors != null && i < cupAnchors.Length && cupAnchors[i] != null)
            {
                cupAnchors[i].gameObject.SetActive(active);
                if (active) Place(cupAnchors[i], CupPositions[i], new Vector2(0.07f, 0.12f));
            }
        }

        // Mi vaso: delante de mi asiento (entre mi asiento 50/60 y el
        // centro de la mesa), más grande que los rivales (docs/18 §2).
        // En Flutter el vaso propio va en esa misma banda (sketch_layout:
        // mi vaso sobre mi avatar, hacia el centro).
        Place(myCup, new Vector2(0.50f, 0.52f), new Vector2(0.09f, 0.16f));
        // Mis dados ocultos: bajo mi vaso (V1). Ver ApplyHiddenDiceState.
        Place(myDiceHidden, new Vector2(0.50f, 0.52f), new Vector2(0.20f, 0.08f));
        // Dados del centro: en el centro de la mesa (V2, ocultos).
        // Se colocan sobre el logo "CACHO O DUDO", por encima de mi
        // vaso (que llega hasta y ≈ 0.44), para no taparlo en reposo;
        // en revelación los vasos se levantan (etapa 2), así que el
        // centro queda libre.
        Place(centerDiceGroup, new Vector2(0.50f, 0.40f), new Vector2(0.22f, 0.08f));
        // Botón VER: marcador visual junto a mi vaso, sin lógica.
        Place(verButton, new Vector2(0.62f, 0.52f), new Vector2(0.08f, 0.06f));

        // Consola: los botones se posicionan por su centro X medido en
        // el mockup. Los hijos de BottomConsole deben existir en la
        // jerarquía de Mesa.unity.txt con estos nombres; si falta uno,
        // se avisa y se sigue (no se crea de código).
        PlaceConsoleChild("EmotesButton", EmotesX); // C9: reacciones/emotes, chat de texto fuera
        PlaceConsoleChild("Tile1", Tile1X);
        PlaceConsoleChild("Tile6", Tile6X);
        PlaceConsoleChild("CalzoButton", CalzoX);
        PlaceConsoleChild("DudoButton", DudoX);
        PlaceConsoleChild("PasoButton", PasoX);
    }

    // Paño por tier Flutter vigente. Solo cambia el color del Image de
    // la mesa si existe; el paño definitivo por tier llega con el
    // glTF/textura de Blender (ASSETS_NEEDED.md). Los montos de lobby
    // de docs/18 §7 siguen ABIERTOS y no se aplican aquí.
    public void ApplyTierFelt(int stake)
    {
        Color felt = FeltCharcoalCenter; // Casino 500 por defecto
        switch (stake)
        {
            case 100: felt = FeltBarrioCenter; break;
            case 250: felt = FeltSalonCenter; break;
            case 1000: felt = FeltVipCenter; break;
            case 2500: felt = FeltHighRollerCenter; break;
            default: felt = FeltCharcoalCenter; break;
        }
        if (tableArea != null)
        {
            Image image = tableArea.GetComponent<Image>();
            if (image != null) image.color = felt;
        }
    }

    // Estado visual de dados ocultos (V1 + V2). Sin lógica de juego:
    // mis dados y los del centro nacen NO visibles. El botón VER no
    // los muestra en esta etapa (eso es etapa 2, tras aprobar la 1).
    private void ApplyHiddenDiceState()
    {
        if (myDiceHidden != null) myDiceHidden.gameObject.SetActive(false);
        if (centerDiceGroup != null) centerDiceGroup.gameObject.SetActive(false);
        if (verButton != null) verButton.gameObject.SetActive(true); // marcador visual, sin lógica
        if (myCup != null) myCup.gameObject.SetActive(true); // vaso cerrado: tapa los dados
    }

    // Coloca un RectTransform por su centro en % (x desde la izquierda,
    // y desde ARRIBA, como el mockup y Flutter) y su tamaño en % de
    // pantalla. Conversión Y: ancla Unity = 1 - yDesdeArriba.
    private void Place(RectTransform rt, Vector2 centerFromTop, Vector2 sizeFraction)
    {
        if (rt == null) return;
        rt.anchorMin = new Vector2(centerFromTop.x, 1f - centerFromTop.y);
        rt.anchorMax = rt.anchorMin;
        rt.anchoredPosition = Vector2.zero;
        rt.sizeDelta = new Vector2(
            sizeFraction.x * Screen.width,
            sizeFraction.y * Screen.height);
    }

    // Banda de ancho completo y alto fijo en px (barra superior y
    // consola): anclada arriba o abajo, sin depender de la escena.
    private void PlaceFullWidth(RectTransform rt, float x, float yEdge, float heightPx, bool fromTop)
    {
        if (rt == null) return;
        if (fromTop)
        {
            rt.anchorMin = new Vector2(0f, 1f);
            rt.anchorMax = new Vector2(1f, 1f);
            rt.anchoredPosition = new Vector2(0f, -heightPx / 2f);
        }
        else
        {
            rt.anchorMin = new Vector2(0f, 0f);
            rt.anchorMax = new Vector2(1f, 0f);
            rt.anchoredPosition = new Vector2(0f, heightPx / 2f);
        }
        rt.sizeDelta = new Vector2(0f, heightPx);
    }

    // Hijo de la consola por nombre (jerarquía de Mesa.unity.txt).
    // Solo posiciona en X; el alto lo da la banda de la consola.
    private void PlaceConsoleChild(string childName, float centerX)
    {
        if (bottomConsole == null) return;
        Transform child = bottomConsole.Find(childName);
        if (child == null)
        {
            Debug.LogWarning("[TableLayout] Falta en BottomConsole: " + childName + " (ver Mesa.unity.txt).");
            return;
        }
        RectTransform rt = child as RectTransform;
        if (rt == null) return;
        rt.anchorMin = new Vector2(centerX, 0.5f);
        rt.anchorMax = rt.anchorMin;
        rt.anchoredPosition = Vector2.zero;
    }
}
