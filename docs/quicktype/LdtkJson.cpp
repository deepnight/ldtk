//  To parse this JSON data, first install
//
//      Boost     http://www.boost.org
//      json.hpp  https://github.com/nlohmann/json
//
//  Then include this file, and then do
//
//     LdtkJson data = nlohmann::json::parse(jsonString);

#pragma once

#include <boost/optional.hpp>
#include "json.hpp"

#include <boost/optional.hpp>
#include <stdexcept>
#include <regex>

#ifndef NLOHMANN_OPT_HELPER
#define NLOHMANN_OPT_HELPER
namespace nlohmann {
    template <typename T>
    struct adl_serializer<std::shared_ptr<T>> {
        static void to_json(json & j, const std::shared_ptr<T> & opt) {
            if (!opt) j = nullptr; else j = *opt;
        }

        static std::shared_ptr<T> from_json(const json & j) {
            if (j.is_null()) return std::make_shared<T>(); else return std::make_shared<T>(j.get<T>());
        }
    };
    template <typename T>
    struct adl_serializer<boost::optional<T>> {
        static void to_json(json & j, const boost::optional<T> & opt) {
            if (!opt) j = nullptr; else j = *opt;
        }

        static boost::optional<T> from_json(const json & j) {
            if (j.is_null()) return boost::optional<T>(); else return boost::optional<T>(j.get<T>());
        }
    };
}
#endif

namespace quicktype {
    using nlohmann::json;

    #ifndef NLOHMANN_UNTYPED_quicktype_HELPER
    #define NLOHMANN_UNTYPED_quicktype_HELPER
    inline json get_untyped(const json & j, const char * property) {
        if (j.find(property) != j.end()) {
            return j.at(property).get<json>();
        }
        return json();
    }

    inline json get_untyped(const json & j, std::string property) {
        return get_untyped(j, property.data());
    }
    #endif

    #ifndef NLOHMANN_OPTIONAL_quicktype_HELPER
    #define NLOHMANN_OPTIONAL_quicktype_HELPER
    template <typename T>
    inline std::shared_ptr<T> get_heap_optional(const json & j, const char * property) {
        auto it = j.find(property);
        if (it != j.end() && !it->is_null()) {
            return j.at(property).get<std::shared_ptr<T>>();
        }
        return std::shared_ptr<T>();
    }

    template <typename T>
    inline std::shared_ptr<T> get_heap_optional(const json & j, std::string property) {
        return get_heap_optional<T>(j, property.data());
    }
    template <typename T>
    inline boost::optional<T> get_stack_optional(const json & j, const char * property) {
        auto it = j.find(property);
        if (it != j.end() && !it->is_null()) {
            return j.at(property).get<boost::optional<T>>();
        }
        return boost::optional<T>();
    }

    template <typename T>
    inline boost::optional<T> get_stack_optional(const json & j, std::string property) {
        return get_stack_optional<T>(j, property.data());
    }
    #endif

    /**
     * Possible values: `Manual`, `AfterLoad`, `BeforeSave`, `AfterSave`
     */
    enum class When : int { AFTER_LOAD, AFTER_SAVE, BEFORE_SAVE, MANUAL };

    class LdtkCustomCommand {
        public:
        LdtkCustomCommand() = default;
        virtual ~LdtkCustomCommand() = default;

        private:
        std::string command;
        When when;

        public:
        const std::string & get_command() const { return command; }
        std::string & get_mutable_command() { return command; }
        void set_command(const std::string & value) { this->command = value; }

        /**
         * Possible values: `Manual`, `AfterLoad`, `BeforeSave`, `AfterSave`
         */
        const When & get_when() const { return when; }
        When & get_mutable_when() { return when; }
        void set_when(const When & value) { this->when = value; }
    };

    /**
     * Possible values: `Any`, `OnlySame`, `OnlyTags`, `OnlySpecificEntity`
     */
    enum class AllowedRefs : int { ANY, ONLY_SAME, ONLY_SPECIFIC_ENTITY, ONLY_TAGS };

    /**
     * Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `LevelTile`,
     * `Points`, `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`,
     * `ArrayCountWithLabel`, `ArrayCountNoLabel`, `RefLinkBetweenPivots`,
     * `RefLinkBetweenCenters`
     */
    enum class EditorDisplayMode : int { ARRAY_COUNT_NO_LABEL, ARRAY_COUNT_WITH_LABEL, ENTITY_TILE, HIDDEN, LEVEL_TILE, NAME_AND_VALUE, POINTS, POINT_PATH, POINT_PATH_LOOP, POINT_STAR, RADIUS_GRID, RADIUS_PX, REF_LINK_BETWEEN_CENTERS, REF_LINK_BETWEEN_PIVOTS, VALUE_ONLY };

    /**
     * Possible values: `Above`, `Center`, `Beneath`
     */
    enum class EditorDisplayPos : int { ABOVE, BENEATH, CENTER };

    /**
     * Possible values: `ZigZag`, `StraightArrow`, `CurvedArrow`, `ArrowsLine`, `DashedLine`
     */
    enum class EditorLinkStyle : int { ARROWS_LINE, CURVED_ARROW, DASHED_LINE, STRAIGHT_ARROW, ZIG_ZAG };

    enum class TextLanguageMode : int { LANG_C, LANG_HAXE, LANG_JS, LANG_JSON, LANG_LOG, LANG_LUA, LANG_MARKDOWN, LANG_PYTHON, LANG_RUBY, LANG_XML };

    /**
     * This section is mostly only intended for the LDtk editor app itself. You can safely
     * ignore it.
     */
    class FieldDefinition {
        public:
        FieldDefinition() = default;
        virtual ~FieldDefinition() = default;

        private:
        std::string type;
        boost::optional<std::vector<std::string>> accept_file_types;
        AllowedRefs allowed_refs;
        boost::optional<int64_t> allowed_refs_entity_uid;
        std::vector<std::string> allowed_ref_tags;
        bool allow_out_of_level_ref;
        boost::optional<int64_t> array_max_length;
        boost::optional<int64_t> array_min_length;
        bool auto_chain_ref;
        bool can_be_null;
        nlohmann::json default_override;
        boost::optional<std::string> doc;
        bool editor_always_show;
        bool editor_cut_long_values;
        boost::optional<std::string> editor_display_color;
        EditorDisplayMode editor_display_mode;
        EditorDisplayPos editor_display_pos;
        double editor_display_scale;
        EditorLinkStyle editor_link_style;
        bool editor_show_in_world;
        boost::optional<std::string> editor_text_prefix;
        boost::optional<std::string> editor_text_suffix;
        std::string identifier;
        bool is_array;
        boost::optional<double> max;
        boost::optional<double> min;
        boost::optional<std::string> regex;
        bool symmetrical_ref;
        boost::optional<TextLanguageMode> text_language_mode;
        boost::optional<int64_t> tileset_uid;
        std::string field_definition_type;
        int64_t uid;
        bool use_for_smart_color;

        public:
        /**
         * Human readable value type. Possible values: `Int, Float, String, Bool, Color,
         * ExternEnum.XXX, LocalEnum.XXX, Point, FilePath`.<br/>  If the field is an array, this
         * field will look like `Array<...>` (eg. `Array<Int>`, `Array<Point>` etc.)<br/>  NOTE: if
         * you enable the advanced option **Use Multilines type**, you will have "*Multilines*"
         * instead of "*String*" when relevant.
         */
        const std::string & get_type() const { return type; }
        std::string & get_mutable_type() { return type; }
        void set_type(const std::string & value) { this->type = value; }

        /**
         * Optional list of accepted file extensions for FilePath value type. Includes the dot:
         * `.ext`
         */
        boost::optional<std::vector<std::string>> get_accept_file_types() const { return accept_file_types; }
        void set_accept_file_types(boost::optional<std::vector<std::string>> value) { this->accept_file_types = value; }

        /**
         * Possible values: `Any`, `OnlySame`, `OnlyTags`, `OnlySpecificEntity`
         */
        const AllowedRefs & get_allowed_refs() const { return allowed_refs; }
        AllowedRefs & get_mutable_allowed_refs() { return allowed_refs; }
        void set_allowed_refs(const AllowedRefs & value) { this->allowed_refs = value; }

        boost::optional<int64_t> get_allowed_refs_entity_uid() const { return allowed_refs_entity_uid; }
        void set_allowed_refs_entity_uid(boost::optional<int64_t> value) { this->allowed_refs_entity_uid = value; }

        const std::vector<std::string> & get_allowed_ref_tags() const { return allowed_ref_tags; }
        std::vector<std::string> & get_mutable_allowed_ref_tags() { return allowed_ref_tags; }
        void set_allowed_ref_tags(const std::vector<std::string> & value) { this->allowed_ref_tags = value; }

        const bool & get_allow_out_of_level_ref() const { return allow_out_of_level_ref; }
        bool & get_mutable_allow_out_of_level_ref() { return allow_out_of_level_ref; }
        void set_allow_out_of_level_ref(const bool & value) { this->allow_out_of_level_ref = value; }

        /**
         * Array max length
         */
        boost::optional<int64_t> get_array_max_length() const { return array_max_length; }
        void set_array_max_length(boost::optional<int64_t> value) { this->array_max_length = value; }

        /**
         * Array min length
         */
        boost::optional<int64_t> get_array_min_length() const { return array_min_length; }
        void set_array_min_length(boost::optional<int64_t> value) { this->array_min_length = value; }

        const bool & get_auto_chain_ref() const { return auto_chain_ref; }
        bool & get_mutable_auto_chain_ref() { return auto_chain_ref; }
        void set_auto_chain_ref(const bool & value) { this->auto_chain_ref = value; }

        /**
         * TRUE if the value can be null. For arrays, TRUE means it can contain null values
         * (exception: array of Points can't have null values).
         */
        const bool & get_can_be_null() const { return can_be_null; }
        bool & get_mutable_can_be_null() { return can_be_null; }
        void set_can_be_null(const bool & value) { this->can_be_null = value; }

        /**
         * Default value if selected value is null or invalid.
         */
        const nlohmann::json & get_default_override() const { return default_override; }
        nlohmann::json & get_mutable_default_override() { return default_override; }
        void set_default_override(const nlohmann::json & value) { this->default_override = value; }

        /**
         * User defined documentation for this field to provide help/tips to level designers about
         * accepted values.
         */
        boost::optional<std::string> get_doc() const { return doc; }
        void set_doc(boost::optional<std::string> value) { this->doc = value; }

        const bool & get_editor_always_show() const { return editor_always_show; }
        bool & get_mutable_editor_always_show() { return editor_always_show; }
        void set_editor_always_show(const bool & value) { this->editor_always_show = value; }

        const bool & get_editor_cut_long_values() const { return editor_cut_long_values; }
        bool & get_mutable_editor_cut_long_values() { return editor_cut_long_values; }
        void set_editor_cut_long_values(const bool & value) { this->editor_cut_long_values = value; }

        boost::optional<std::string> get_editor_display_color() const { return editor_display_color; }
        void set_editor_display_color(boost::optional<std::string> value) { this->editor_display_color = value; }

        /**
         * Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `LevelTile`,
         * `Points`, `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`,
         * `ArrayCountWithLabel`, `ArrayCountNoLabel`, `RefLinkBetweenPivots`,
         * `RefLinkBetweenCenters`
         */
        const EditorDisplayMode & get_editor_display_mode() const { return editor_display_mode; }
        EditorDisplayMode & get_mutable_editor_display_mode() { return editor_display_mode; }
        void set_editor_display_mode(const EditorDisplayMode & value) { this->editor_display_mode = value; }

        /**
         * Possible values: `Above`, `Center`, `Beneath`
         */
        const EditorDisplayPos & get_editor_display_pos() const { return editor_display_pos; }
        EditorDisplayPos & get_mutable_editor_display_pos() { return editor_display_pos; }
        void set_editor_display_pos(const EditorDisplayPos & value) { this->editor_display_pos = value; }

        const double & get_editor_display_scale() const { return editor_display_scale; }
        double & get_mutable_editor_display_scale() { return editor_display_scale; }
        void set_editor_display_scale(const double & value) { this->editor_display_scale = value; }

        /**
         * Possible values: `ZigZag`, `StraightArrow`, `CurvedArrow`, `ArrowsLine`, `DashedLine`
         */
        const EditorLinkStyle & get_editor_link_style() const { return editor_link_style; }
        EditorLinkStyle & get_mutable_editor_link_style() { return editor_link_style; }
        void set_editor_link_style(const EditorLinkStyle & value) { this->editor_link_style = value; }

        const bool & get_editor_show_in_world() const { return editor_show_in_world; }
        bool & get_mutable_editor_show_in_world() { return editor_show_in_world; }
        void set_editor_show_in_world(const bool & value) { this->editor_show_in_world = value; }

        boost::optional<std::string> get_editor_text_prefix() const { return editor_text_prefix; }
        void set_editor_text_prefix(boost::optional<std::string> value) { this->editor_text_prefix = value; }

        boost::optional<std::string> get_editor_text_suffix() const { return editor_text_suffix; }
        void set_editor_text_suffix(boost::optional<std::string> value) { this->editor_text_suffix = value; }

        /**
         * User defined unique identifier
         */
        const std::string & get_identifier() const { return identifier; }
        std::string & get_mutable_identifier() { return identifier; }
        void set_identifier(const std::string & value) { this->identifier = value; }

        /**
         * TRUE if the value is an array of multiple values
         */
        const bool & get_is_array() const { return is_array; }
        bool & get_mutable_is_array() { return is_array; }
        void set_is_array(const bool & value) { this->is_array = value; }

        /**
         * Max limit for value, if applicable
         */
        boost::optional<double> get_max() const { return max; }
        void set_max(boost::optional<double> value) { this->max = value; }

        /**
         * Min limit for value, if applicable
         */
        boost::optional<double> get_min() const { return min; }
        void set_min(boost::optional<double> value) { this->min = value; }

        /**
         * Optional regular expression that needs to be matched to accept values. Expected format:
         * `/some_reg_ex/g`, with optional "i" flag.
         */
        boost::optional<std::string> get_regex() const { return regex; }
        void set_regex(boost::optional<std::string> value) { this->regex = value; }

        const bool & get_symmetrical_ref() const { return symmetrical_ref; }
        bool & get_mutable_symmetrical_ref() { return symmetrical_ref; }
        void set_symmetrical_ref(const bool & value) { this->symmetrical_ref = value; }

        /**
         * Possible values: &lt;`null`&gt;, `LangPython`, `LangRuby`, `LangJS`, `LangLua`, `LangC`,
         * `LangHaxe`, `LangMarkdown`, `LangJson`, `LangXml`, `LangLog`
         */
        boost::optional<TextLanguageMode> get_text_language_mode() const { return text_language_mode; }
        void set_text_language_mode(boost::optional<TextLanguageMode> value) { this->text_language_mode = value; }

        /**
         * UID of the tileset used for a Tile
         */
        boost::optional<int64_t> get_tileset_uid() const { return tileset_uid; }
        void set_tileset_uid(boost::optional<int64_t> value) { this->tileset_uid = value; }

        /**
         * Internal enum representing the possible field types. Possible values: F_Int, F_Float,
         * F_String, F_Text, F_Bool, F_Color, F_Enum(...), F_Point, F_Path, F_EntityRef, F_Tile
         */
        const std::string & get_field_definition_type() const { return field_definition_type; }
        std::string & get_mutable_field_definition_type() { return field_definition_type; }
        void set_field_definition_type(const std::string & value) { this->field_definition_type = value; }

        /**
         * Unique Int identifier
         */
        const int64_t & get_uid() const { return uid; }
        int64_t & get_mutable_uid() { return uid; }
        void set_uid(const int64_t & value) { this->uid = value; }

        /**
         * If TRUE, the color associated with this field will override the Entity or Level default
         * color in the editor UI. For Enum fields, this would be the color associated to their
         * values.
         */
        const bool & get_use_for_smart_color() const { return use_for_smart_color; }
        bool & get_mutable_use_for_smart_color() { return use_for_smart_color; }
        void set_use_for_smart_color(const bool & value) { this->use_for_smart_color = value; }
    };

    /**
     * Possible values: `DiscardOldOnes`, `PreventAdding`, `MoveLastOne`
     */
    enum class LimitBehavior : int { DISCARD_OLD_ONES, MOVE_LAST_ONE, PREVENT_ADDING };

    /**
     * If TRUE, the maxCount is a "per world" limit, if FALSE, it's a "per level". Possible
     * values: `PerLayer`, `PerLevel`, `PerWorld`
     */
    enum class LimitScope : int { PER_LAYER, PER_LEVEL, PER_WORLD };

    /**
     * Possible values: `Rectangle`, `Ellipse`, `Tile`, `Cross`
     */
    enum class RenderMode : int { CROSS, ELLIPSE, RECTANGLE, TILE };

    /**
     * This object represents a custom sub rectangle in a Tileset image.
     */
    class TilesetRectangle {
        public:
        TilesetRectangle() = default;
        virtual ~TilesetRectangle() = default;

        private:
        int64_t h;
        int64_t tileset_uid;
        int64_t w;
        int64_t x;
        int64_t y;

        public:
        /**
         * Height in pixels
         */
        const int64_t & get_h() const { return h; }
        int64_t & get_mutable_h() { return h; }
        void set_h(const int64_t & value) { this->h = value; }

        /**
         * UID of the tileset
         */
        const int64_t & get_tileset_uid() const { return tileset_uid; }
        int64_t & get_mutable_tileset_uid() { return tileset_uid; }
        void set_tileset_uid(const int64_t & value) { this->tileset_uid = value; }

        /**
         * Width in pixels
         */
        const int64_t & get_w() const { return w; }
        int64_t & get_mutable_w() { return w; }
        void set_w(const int64_t & value) { this->w = value; }

        /**
         * X pixels coordinate of the top-left corner in the Tileset image
         */
        const int64_t & get_x() const { return x; }
        int64_t & get_mutable_x() { return x; }
        void set_x(const int64_t & value) { this->x = value; }

        /**
         * Y pixels coordinate of the top-left corner in the Tileset image
         */
        const int64_t & get_y() const { return y; }
        int64_t & get_mutable_y() { return y; }
        void set_y(const int64_t & value) { this->y = value; }
    };

    /**
     * An enum describing how the the Entity tile is rendered inside the Entity bounds. Possible
     * values: `Cover`, `FitInside`, `Repeat`, `Stretch`, `FullSizeCropped`,
     * `FullSizeUncropped`, `NineSlice`
     */
    enum class TileRenderMode : int { COVER, FIT_INSIDE, FULL_SIZE_CROPPED, FULL_SIZE_UNCROPPED, NINE_SLICE, REPEAT, STRETCH };

    class EntityDefinition {
        public:
        EntityDefinition() = default;
        virtual ~EntityDefinition() = default;

        private:
        std::string color;
        boost::optional<std::string> doc;
        bool export_to_toc;
        std::vector<FieldDefinition> field_defs;
        double fill_opacity;
        int64_t height;
        bool hollow;
        std::string identifier;
        bool keep_aspect_ratio;
        LimitBehavior limit_behavior;
        LimitScope limit_scope;
        double line_opacity;
        int64_t max_count;
        boost::optional<int64_t> max_height;
        boost::optional<int64_t> max_width;
        boost::optional<int64_t> min_height;
        boost::optional<int64_t> min_width;
        std::vector<int64_t> nine_slice_borders;
        double pivot_x;
        double pivot_y;
        RenderMode render_mode;
        bool resizable_x;
        bool resizable_y;
        bool show_name;
        std::vector<std::string> tags;
        boost::optional<int64_t> tile_id;
        double tile_opacity;
        boost::optional<TilesetRectangle> tile_rect;
        TileRenderMode tile_render_mode;
        boost::optional<int64_t> tileset_id;
        int64_t uid;
        boost::optional<TilesetRectangle> ui_tile_rect;
        int64_t width;

        public:
        /**
         * Base entity color
         */
        const std::string & get_color() const { return color; }
        std::string & get_mutable_color() { return color; }
        void set_color(const std::string & value) { this->color = value; }

        /**
         * User defined documentation for this element to provide help/tips to level designers.
         */
        boost::optional<std::string> get_doc() const { return doc; }
        void set_doc(boost::optional<std::string> value) { this->doc = value; }

        /**
         * If enabled, all instances of this entity will be listed in the project "Table of content"
         * object.
         */
        const bool & get_export_to_toc() const { return export_to_toc; }
        bool & get_mutable_export_to_toc() { return export_to_toc; }
        void set_export_to_toc(const bool & value) { this->export_to_toc = value; }

        /**
         * Array of field definitions
         */
        const std::vector<FieldDefinition> & get_field_defs() const { return field_defs; }
        std::vector<FieldDefinition> & get_mutable_field_defs() { return field_defs; }
        void set_field_defs(const std::vector<FieldDefinition> & value) { this->field_defs = value; }

        const double & get_fill_opacity() const { return fill_opacity; }
        double & get_mutable_fill_opacity() { return fill_opacity; }
        void set_fill_opacity(const double & value) { this->fill_opacity = value; }

        /**
         * Pixel height
         */
        const int64_t & get_height() const { return height; }
        int64_t & get_mutable_height() { return height; }
        void set_height(const int64_t & value) { this->height = value; }

        const bool & get_hollow() const { return hollow; }
        bool & get_mutable_hollow() { return hollow; }
        void set_hollow(const bool & value) { this->hollow = value; }

        /**
         * User defined unique identifier
         */
        const std::string & get_identifier() const { return identifier; }
        std::string & get_mutable_identifier() { return identifier; }
        void set_identifier(const std::string & value) { this->identifier = value; }

        /**
         * Only applies to entities resizable on both X/Y. If TRUE, the entity instance width/height
         * will keep the same aspect ratio as the definition.
         */
        const bool & get_keep_aspect_ratio() const { return keep_aspect_ratio; }
        bool & get_mutable_keep_aspect_ratio() { return keep_aspect_ratio; }
        void set_keep_aspect_ratio(const bool & value) { this->keep_aspect_ratio = value; }

        /**
         * Possible values: `DiscardOldOnes`, `PreventAdding`, `MoveLastOne`
         */
        const LimitBehavior & get_limit_behavior() const { return limit_behavior; }
        LimitBehavior & get_mutable_limit_behavior() { return limit_behavior; }
        void set_limit_behavior(const LimitBehavior & value) { this->limit_behavior = value; }

        /**
         * If TRUE, the maxCount is a "per world" limit, if FALSE, it's a "per level". Possible
         * values: `PerLayer`, `PerLevel`, `PerWorld`
         */
        const LimitScope & get_limit_scope() const { return limit_scope; }
        LimitScope & get_mutable_limit_scope() { return limit_scope; }
        void set_limit_scope(const LimitScope & value) { this->limit_scope = value; }

        const double & get_line_opacity() const { return line_opacity; }
        double & get_mutable_line_opacity() { return line_opacity; }
        void set_line_opacity(const double & value) { this->line_opacity = value; }

        /**
         * Max instances count
         */
        const int64_t & get_max_count() const { return max_count; }
        int64_t & get_mutable_max_count() { return max_count; }
        void set_max_count(const int64_t & value) { this->max_count = value; }

        /**
         * Max pixel height (only applies if the entity is resizable on Y)
         */
        boost::optional<int64_t> get_max_height() const { return max_height; }
        void set_max_height(boost::optional<int64_t> value) { this->max_height = value; }

        /**
         * Max pixel width (only applies if the entity is resizable on X)
         */
        boost::optional<int64_t> get_max_width() const { return max_width; }
        void set_max_width(boost::optional<int64_t> value) { this->max_width = value; }

        /**
         * Min pixel height (only applies if the entity is resizable on Y)
         */
        boost::optional<int64_t> get_min_height() const { return min_height; }
        void set_min_height(boost::optional<int64_t> value) { this->min_height = value; }

        /**
         * Min pixel width (only applies if the entity is resizable on X)
         */
        boost::optional<int64_t> get_min_width() const { return min_width; }
        void set_min_width(boost::optional<int64_t> value) { this->min_width = value; }

        /**
         * An array of 4 dimensions for the up/right/down/left borders (in this order) when using
         * 9-slice mode for `tileRenderMode`.<br/>  If the tileRenderMode is not NineSlice, then
         * this array is empty.<br/>  See: https://en.wikipedia.org/wiki/9-slice_scaling
         */
        const std::vector<int64_t> & get_nine_slice_borders() const { return nine_slice_borders; }
        std::vector<int64_t> & get_mutable_nine_slice_borders() { return nine_slice_borders; }
        void set_nine_slice_borders(const std::vector<int64_t> & value) { this->nine_slice_borders = value; }

        /**
         * Pivot X coordinate (from 0 to 1.0)
         */
        const double & get_pivot_x() const { return pivot_x; }
        double & get_mutable_pivot_x() { return pivot_x; }
        void set_pivot_x(const double & value) { this->pivot_x = value; }

        /**
         * Pivot Y coordinate (from 0 to 1.0)
         */
        const double & get_pivot_y() const { return pivot_y; }
        double & get_mutable_pivot_y() { return pivot_y; }
        void set_pivot_y(const double & value) { this->pivot_y = value; }

        /**
         * Possible values: `Rectangle`, `Ellipse`, `Tile`, `Cross`
         */
        const RenderMode & get_render_mode() const { return render_mode; }
        RenderMode & get_mutable_render_mode() { return render_mode; }
        void set_render_mode(const RenderMode & value) { this->render_mode = value; }

        /**
         * If TRUE, the entity instances will be resizable horizontally
         */
        const bool & get_resizable_x() const { return resizable_x; }
        bool & get_mutable_resizable_x() { return resizable_x; }
        void set_resizable_x(const bool & value) { this->resizable_x = value; }

        /**
         * If TRUE, the entity instances will be resizable vertically
         */
        const bool & get_resizable_y() const { return resizable_y; }
        bool & get_mutable_resizable_y() { return resizable_y; }
        void set_resizable_y(const bool & value) { this->resizable_y = value; }

        /**
         * Display entity name in editor
         */
        const bool & get_show_name() const { return show_name; }
        bool & get_mutable_show_name() { return show_name; }
        void set_show_name(const bool & value) { this->show_name = value; }

        /**
         * An array of strings that classifies this entity
         */
        const std::vector<std::string> & get_tags() const { return tags; }
        std::vector<std::string> & get_mutable_tags() { return tags; }
        void set_tags(const std::vector<std::string> & value) { this->tags = value; }

        /**
         * **WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced
         * by: `tileRect`
         */
        boost::optional<int64_t> get_tile_id() const { return tile_id; }
        void set_tile_id(boost::optional<int64_t> value) { this->tile_id = value; }

        const double & get_tile_opacity() const { return tile_opacity; }
        double & get_mutable_tile_opacity() { return tile_opacity; }
        void set_tile_opacity(const double & value) { this->tile_opacity = value; }

        /**
         * An object representing a rectangle from an existing Tileset
         */
        boost::optional<TilesetRectangle> get_tile_rect() const { return tile_rect; }
        void set_tile_rect(boost::optional<TilesetRectangle> value) { this->tile_rect = value; }

        /**
         * An enum describing how the the Entity tile is rendered inside the Entity bounds. Possible
         * values: `Cover`, `FitInside`, `Repeat`, `Stretch`, `FullSizeCropped`,
         * `FullSizeUncropped`, `NineSlice`
         */
        const TileRenderMode & get_tile_render_mode() const { return tile_render_mode; }
        TileRenderMode & get_mutable_tile_render_mode() { return tile_render_mode; }
        void set_tile_render_mode(const TileRenderMode & value) { this->tile_render_mode = value; }

        /**
         * Tileset ID used for optional tile display
         */
        boost::optional<int64_t> get_tileset_id() const { return tileset_id; }
        void set_tileset_id(boost::optional<int64_t> value) { this->tileset_id = value; }

        /**
         * Unique Int identifier
         */
        const int64_t & get_uid() const { return uid; }
        int64_t & get_mutable_uid() { return uid; }
        void set_uid(const int64_t & value) { this->uid = value; }

        /**
         * This tile overrides the one defined in `tileRect` in the UI
         */
        boost::optional<TilesetRectangle> get_ui_tile_rect() const { return ui_tile_rect; }
        void set_ui_tile_rect(boost::optional<TilesetRectangle> value) { this->ui_tile_rect = value; }

        /**
         * Pixel width
         */
        const int64_t & get_width() const { return width; }
        int64_t & get_mutable_width() { return width; }
        void set_width(const int64_t & value) { this->width = value; }
    };

    class EnumValueDefinition {
        public:
        EnumValueDefinition() = default;
        virtual ~EnumValueDefinition() = default;

        private:
        boost::optional<std::vector<int64_t>> tile_src_rect;
        int64_t color;
        std::string id;
        boost::optional<int64_t> tile_id;
        boost::optional<TilesetRectangle> tile_rect;

        public:
        /**
         * **WARNING**: this deprecated value is no longer exported since version 1.4.0  Replaced
         * by: `tileRect`
         */
        boost::optional<std::vector<int64_t>> get_tile_src_rect() const { return tile_src_rect; }
        void set_tile_src_rect(boost::optional<std::vector<int64_t>> value) { this->tile_src_rect = value; }

        /**
         * Optional color
         */
        const int64_t & get_color() const { return color; }
        int64_t & get_mutable_color() { return color; }
        void set_color(const int64_t & value) { this->color = value; }

        /**
         * Enum value
         */
        const std::string & get_id() const { return id; }
        std::string & get_mutable_id() { return id; }
        void set_id(const std::string & value) { this->id = value; }

        /**
         * **WARNING**: this deprecated value is no longer exported since version 1.4.0  Replaced
         * by: `tileRect`
         */
        boost::optional<int64_t> get_tile_id() const { return tile_id; }
        void set_tile_id(boost::optional<int64_t> value) { this->tile_id = value; }

        /**
         * Optional tileset rectangle to represents this value
         */
        boost::optional<TilesetRectangle> get_tile_rect() const { return tile_rect; }
        void set_tile_rect(boost::optional<TilesetRectangle> value) { this->tile_rect = value; }
    };

    class EnumDefinition {
        public:
        EnumDefinition() = default;
        virtual ~EnumDefinition() = default;

        private:
        boost::optional<std::string> external_file_checksum;
        boost::optional<std::string> external_rel_path;
        boost::optional<int64_t> icon_tileset_uid;
        std::string identifier;
        std::vector<std::string> tags;
        int64_t uid;
        std::vector<EnumValueDefinition> values;

        public:
        boost::optional<std::string> get_external_file_checksum() const { return external_file_checksum; }
        void set_external_file_checksum(boost::optional<std::string> value) { this->external_file_checksum = value; }

        /**
         * Relative path to the external file providing this Enum
         */
        boost::optional<std::string> get_external_rel_path() const { return external_rel_path; }
        void set_external_rel_path(boost::optional<std::string> value) { this->external_rel_path = value; }

        /**
         * Tileset UID if provided
         */
        boost::optional<int64_t> get_icon_tileset_uid() const { return icon_tileset_uid; }
        void set_icon_tileset_uid(boost::optional<int64_t> value) { this->icon_tileset_uid = value; }

        /**
         * User defined unique identifier
         */
        const std::string & get_identifier() const { return identifier; }
        std::string & get_mutable_identifier() { return identifier; }
        void set_identifier(const std::string & value) { this->identifier = value; }

        /**
         * An array of user-defined tags to organize the Enums
         */
        const std::vector<std::string> & get_tags() const { return tags; }
        std::vector<std::string> & get_mutable_tags() { return tags; }
        void set_tags(const std::vector<std::string> & value) { this->tags = value; }

        /**
         * Unique Int identifier
         */
        const int64_t & get_uid() const { return uid; }
        int64_t & get_mutable_uid() { return uid; }
        void set_uid(const int64_t & value) { this->uid = value; }

        /**
         * All possible enum values, with their optional Tile infos.
         */
        const std::vector<EnumValueDefinition> & get_values() const { return values; }
        std::vector<EnumValueDefinition> & get_mutable_values() { return values; }
        void set_values(const std::vector<EnumValueDefinition> & value) { this->values = value; }
    };

    /**
     * Checker mode Possible values: `None`, `Horizontal`, `Vertical`
     */
    enum class Checker : int { HORIZONTAL, NONE, VERTICAL };

    /**
     * Defines how tileIds array is used Possible values: `Single`, `Stamp`
     */
    enum class TileMode : int { SINGLE, STAMP };

    /**
     * This complex section isn't meant to be used by game devs at all, as these rules are
     * completely resolved internally by the editor before any saving. You should just ignore
     * this part.
     */
    class AutoLayerRuleDefinition {
        public:
        AutoLayerRuleDefinition() = default;
        virtual ~AutoLayerRuleDefinition() = default;

        private:
        bool active;
        double alpha;
        bool break_on_match;
        double chance;
        Checker checker;
        bool flip_x;
        bool flip_y;
        boost::optional<int64_t> out_of_bounds_value;
        std::vector<int64_t> pattern;
        bool perlin_active;
        double perlin_octaves;
        double perlin_scale;
        double perlin_seed;
        double pivot_x;
        double pivot_y;
        int64_t size;
        std::vector<int64_t> tile_ids;
        TileMode tile_mode;
        int64_t tile_random_x_max;
        int64_t tile_random_x_min;
        int64_t tile_random_y_max;
        int64_t tile_random_y_min;
        int64_t tile_x_offset;
        int64_t tile_y_offset;
        int64_t uid;
        int64_t x_modulo;
        int64_t x_offset;
        int64_t y_modulo;
        int64_t y_offset;

        public:
        /**
         * If FALSE, the rule effect isn't applied, and no tiles are generated.
         */
        const bool & get_active() const { return active; }
        bool & get_mutable_active() { return active; }
        void set_active(const bool & value) { this->active = value; }

        const double & get_alpha() const { return alpha; }
        double & get_mutable_alpha() { return alpha; }
        void set_alpha(const double & value) { this->alpha = value; }

        /**
         * When TRUE, the rule will prevent other rules to be applied in the same cell if it matches
         * (TRUE by default).
         */
        const bool & get_break_on_match() const { return break_on_match; }
        bool & get_mutable_break_on_match() { return break_on_match; }
        void set_break_on_match(const bool & value) { this->break_on_match = value; }

        /**
         * Chances for this rule to be applied (0 to 1)
         */
        const double & get_chance() const { return chance; }
        double & get_mutable_chance() { return chance; }
        void set_chance(const double & value) { this->chance = value; }

        /**
         * Checker mode Possible values: `None`, `Horizontal`, `Vertical`
         */
        const Checker & get_checker() const { return checker; }
        Checker & get_mutable_checker() { return checker; }
        void set_checker(const Checker & value) { this->checker = value; }

        /**
         * If TRUE, allow rule to be matched by flipping its pattern horizontally
         */
        const bool & get_flip_x() const { return flip_x; }
        bool & get_mutable_flip_x() { return flip_x; }
        void set_flip_x(const bool & value) { this->flip_x = value; }

        /**
         * If TRUE, allow rule to be matched by flipping its pattern vertically
         */
        const bool & get_flip_y() const { return flip_y; }
        bool & get_mutable_flip_y() { return flip_y; }
        void set_flip_y(const bool & value) { this->flip_y = value; }

        /**
         * Default IntGrid value when checking cells outside of level bounds
         */
        boost::optional<int64_t> get_out_of_bounds_value() const { return out_of_bounds_value; }
        void set_out_of_bounds_value(boost::optional<int64_t> value) { this->out_of_bounds_value = value; }

        /**
         * Rule pattern (size x size)
         */
        const std::vector<int64_t> & get_pattern() const { return pattern; }
        std::vector<int64_t> & get_mutable_pattern() { return pattern; }
        void set_pattern(const std::vector<int64_t> & value) { this->pattern = value; }

        /**
         * If TRUE, enable Perlin filtering to only apply rule on specific random area
         */
        const bool & get_perlin_active() const { return perlin_active; }
        bool & get_mutable_perlin_active() { return perlin_active; }
        void set_perlin_active(const bool & value) { this->perlin_active = value; }

        const double & get_perlin_octaves() const { return perlin_octaves; }
        double & get_mutable_perlin_octaves() { return perlin_octaves; }
        void set_perlin_octaves(const double & value) { this->perlin_octaves = value; }

        const double & get_perlin_scale() const { return perlin_scale; }
        double & get_mutable_perlin_scale() { return perlin_scale; }
        void set_perlin_scale(const double & value) { this->perlin_scale = value; }

        const double & get_perlin_seed() const { return perlin_seed; }
        double & get_mutable_perlin_seed() { return perlin_seed; }
        void set_perlin_seed(const double & value) { this->perlin_seed = value; }

        /**
         * X pivot of a tile stamp (0-1)
         */
        const double & get_pivot_x() const { return pivot_x; }
        double & get_mutable_pivot_x() { return pivot_x; }
        void set_pivot_x(const double & value) { this->pivot_x = value; }

        /**
         * Y pivot of a tile stamp (0-1)
         */
        const double & get_pivot_y() const { return pivot_y; }
        double & get_mutable_pivot_y() { return pivot_y; }
        void set_pivot_y(const double & value) { this->pivot_y = value; }

        /**
         * Pattern width & height. Should only be 1,3,5 or 7.
         */
        const int64_t & get_size() const { return size; }
        int64_t & get_mutable_size() { return size; }
        void set_size(const int64_t & value) { this->size = value; }

        /**
         * Array of all the tile IDs. They are used randomly or as stamps, based on `tileMode` value.
         */
        const std::vector<int64_t> & get_tile_ids() const { return tile_ids; }
        std::vector<int64_t> & get_mutable_tile_ids() { return tile_ids; }
        void set_tile_ids(const std::vector<int64_t> & value) { this->tile_ids = value; }

        /**
         * Defines how tileIds array is used Possible values: `Single`, `Stamp`
         */
        const TileMode & get_tile_mode() const { return tile_mode; }
        TileMode & get_mutable_tile_mode() { return tile_mode; }
        void set_tile_mode(const TileMode & value) { this->tile_mode = value; }

        /**
         * Max random offset for X tile pos
         */
        const int64_t & get_tile_random_x_max() const { return tile_random_x_max; }
        int64_t & get_mutable_tile_random_x_max() { return tile_random_x_max; }
        void set_tile_random_x_max(const int64_t & value) { this->tile_random_x_max = value; }

        /**
         * Min random offset for X tile pos
         */
        const int64_t & get_tile_random_x_min() const { return tile_random_x_min; }
        int64_t & get_mutable_tile_random_x_min() { return tile_random_x_min; }
        void set_tile_random_x_min(const int64_t & value) { this->tile_random_x_min = value; }

        /**
         * Max random offset for Y tile pos
         */
        const int64_t & get_tile_random_y_max() const { return tile_random_y_max; }
        int64_t & get_mutable_tile_random_y_max() { return tile_random_y_max; }
        void set_tile_random_y_max(const int64_t & value) { this->tile_random_y_max = value; }

        /**
         * Min random offset for Y tile pos
         */
        const int64_t & get_tile_random_y_min() const { return tile_random_y_min; }
        int64_t & get_mutable_tile_random_y_min() { return tile_random_y_min; }
        void set_tile_random_y_min(const int64_t & value) { this->tile_random_y_min = value; }

        /**
         * Tile X offset
         */
        const int64_t & get_tile_x_offset() const { return tile_x_offset; }
        int64_t & get_mutable_tile_x_offset() { return tile_x_offset; }
        void set_tile_x_offset(const int64_t & value) { this->tile_x_offset = value; }

        /**
         * Tile Y offset
         */
        const int64_t & get_tile_y_offset() const { return tile_y_offset; }
        int64_t & get_mutable_tile_y_offset() { return tile_y_offset; }
        void set_tile_y_offset(const int64_t & value) { this->tile_y_offset = value; }

        /**
         * Unique Int identifier
         */
        const int64_t & get_uid() const { return uid; }
        int64_t & get_mutable_uid() { return uid; }
        void set_uid(const int64_t & value) { this->uid = value; }

        /**
         * X cell coord modulo
         */
        const int64_t & get_x_modulo() const { return x_modulo; }
        int64_t & get_mutable_x_modulo() { return x_modulo; }
        void set_x_modulo(const int64_t & value) { this->x_modulo = value; }

        /**
         * X cell start offset
         */
        const int64_t & get_x_offset() const { return x_offset; }
        int64_t & get_mutable_x_offset() { return x_offset; }
        void set_x_offset(const int64_t & value) { this->x_offset = value; }

        /**
         * Y cell coord modulo
         */
        const int64_t & get_y_modulo() const { return y_modulo; }
        int64_t & get_mutable_y_modulo() { return y_modulo; }
        void set_y_modulo(const int64_t & value) { this->y_modulo = value; }

        /**
         * Y cell start offset
         */
        const int64_t & get_y_offset() const { return y_offset; }
        int64_t & get_mutable_y_offset() { return y_offset; }
        void set_y_offset(const int64_t & value) { this->y_offset = value; }
    };

    class AutoLayerRuleGroup {
        public:
        AutoLayerRuleGroup() = default;
        virtual ~AutoLayerRuleGroup() = default;

        private:
        bool active;
        boost::optional<bool> collapsed;
        boost::optional<std::string> color;
        boost::optional<TilesetRectangle> icon;
        bool is_optional;
        std::string name;
        std::vector<AutoLayerRuleDefinition> rules;
        int64_t uid;
        bool uses_wizard;

        public:
        const bool & get_active() const { return active; }
        bool & get_mutable_active() { return active; }
        void set_active(const bool & value) { this->active = value; }

        /**
         * *This field was removed in 1.0.0 and should no longer be used.*
         */
        boost::optional<bool> get_collapsed() const { return collapsed; }
        void set_collapsed(boost::optional<bool> value) { this->collapsed = value; }

        boost::optional<std::string> get_color() const { return color; }
        void set_color(boost::optional<std::string> value) { this->color = value; }

        boost::optional<TilesetRectangle> get_icon() const { return icon; }
        void set_icon(boost::optional<TilesetRectangle> value) { this->icon = value; }

        const bool & get_is_optional() const { return is_optional; }
        bool & get_mutable_is_optional() { return is_optional; }
        void set_is_optional(const bool & value) { this->is_optional = value; }

        const std::string & get_name() const { return name; }
        std::string & get_mutable_name() { return name; }
        void set_name(const std::string & value) { this->name = value; }

        const std::vector<AutoLayerRuleDefinition> & get_rules() const { return rules; }
        std::vector<AutoLayerRuleDefinition> & get_mutable_rules() { return rules; }
        void set_rules(const std::vector<AutoLayerRuleDefinition> & value) { this->rules = value; }

        const int64_t & get_uid() const { return uid; }
        int64_t & get_mutable_uid() { return uid; }
        void set_uid(const int64_t & value) { this->uid = value; }

        const bool & get_uses_wizard() const { return uses_wizard; }
        bool & get_mutable_uses_wizard() { return uses_wizard; }
        void set_uses_wizard(const bool & value) { this->uses_wizard = value; }
    };

    /**
     * IntGrid value definition
     */
    class IntGridValueDefinition {
        public:
        IntGridValueDefinition() = default;
        virtual ~IntGridValueDefinition() = default;

        private:
        std::string color;
        int64_t group_uid;
        boost::optional<std::string> identifier;
        boost::optional<TilesetRectangle> tile;
        int64_t value;

        public:
        const std::string & get_color() const { return color; }
        std::string & get_mutable_color() { return color; }
        void set_color(const std::string & value) { this->color = value; }

        /**
         * Parent group identifier (0 if none)
         */
        const int64_t & get_group_uid() const { return group_uid; }
        int64_t & get_mutable_group_uid() { return group_uid; }
        void set_group_uid(const int64_t & value) { this->group_uid = value; }

        /**
         * User defined unique identifier
         */
        boost::optional<std::string> get_identifier() const { return identifier; }
        void set_identifier(boost::optional<std::string> value) { this->identifier = value; }

        boost::optional<TilesetRectangle> get_tile() const { return tile; }
        void set_tile(boost::optional<TilesetRectangle> value) { this->tile = value; }

        /**
         * The IntGrid value itself
         */
        const int64_t & get_value() const { return value; }
        int64_t & get_mutable_value() { return value; }
        void set_value(const int64_t & value) { this->value = value; }
    };

    /**
     * IntGrid value group definition
     */
    class IntGridValueGroupDefinition {
        public:
        IntGridValueGroupDefinition() = default;
        virtual ~IntGridValueGroupDefinition() = default;

        private:
        boost::optional<std::string> color;
        boost::optional<std::string> identifier;
        int64_t uid;

        public:
        /**
         * User defined color
         */
        boost::optional<std::string> get_color() const { return color; }
        void set_color(boost::optional<std::string> value) { this->color = value; }

        /**
         * User defined string identifier
         */
        boost::optional<std::string> get_identifier() const { return identifier; }
        void set_identifier(boost::optional<std::string> value) { this->identifier = value; }

        /**
         * Group unique ID
         */
        const int64_t & get_uid() const { return uid; }
        int64_t & get_mutable_uid() { return uid; }
        void set_uid(const int64_t & value) { this->uid = value; }
    };

    /**
     * Type of the layer as Haxe Enum Possible values: `IntGrid`, `Entities`, `Tiles`,
     * `AutoLayer`
     */
    enum class Type : int { AUTO_LAYER, ENTITIES, INT_GRID, TILES };

    class LayerDefinition {
        public:
        LayerDefinition() = default;
        virtual ~LayerDefinition() = default;

        private:
        std::string type;
        std::vector<AutoLayerRuleGroup> auto_rule_groups;
        boost::optional<int64_t> auto_source_layer_def_uid;
        boost::optional<int64_t> auto_tileset_def_uid;
        bool can_select_when_inactive;
        double display_opacity;
        boost::optional<std::string> doc;
        std::vector<std::string> excluded_tags;
        int64_t grid_size;
        int64_t guide_grid_hei;
        int64_t guide_grid_wid;
        bool hide_fields_when_inactive;
        bool hide_in_list;
        std::string identifier;
        double inactive_opacity;
        std::vector<IntGridValueDefinition> int_grid_values;
        std::vector<IntGridValueGroupDefinition> int_grid_values_groups;
        double parallax_factor_x;
        double parallax_factor_y;
        bool parallax_scaling;
        int64_t px_offset_x;
        int64_t px_offset_y;
        bool render_in_world_view;
        std::vector<std::string> required_tags;
        double tile_pivot_x;
        double tile_pivot_y;
        boost::optional<int64_t> tileset_def_uid;
        Type layer_definition_type;
        boost::optional<std::string> ui_color;
        int64_t uid;

        public:
        /**
         * Type of the layer (*IntGrid, Entities, Tiles or AutoLayer*)
         */
        const std::string & get_type() const { return type; }
        std::string & get_mutable_type() { return type; }
        void set_type(const std::string & value) { this->type = value; }

        /**
         * Contains all the auto-layer rule definitions.
         */
        const std::vector<AutoLayerRuleGroup> & get_auto_rule_groups() const { return auto_rule_groups; }
        std::vector<AutoLayerRuleGroup> & get_mutable_auto_rule_groups() { return auto_rule_groups; }
        void set_auto_rule_groups(const std::vector<AutoLayerRuleGroup> & value) { this->auto_rule_groups = value; }

        boost::optional<int64_t> get_auto_source_layer_def_uid() const { return auto_source_layer_def_uid; }
        void set_auto_source_layer_def_uid(boost::optional<int64_t> value) { this->auto_source_layer_def_uid = value; }

        /**
         * **WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced
         * by: `tilesetDefUid`
         */
        boost::optional<int64_t> get_auto_tileset_def_uid() const { return auto_tileset_def_uid; }
        void set_auto_tileset_def_uid(boost::optional<int64_t> value) { this->auto_tileset_def_uid = value; }

        /**
         * Allow editor selections when the layer is not currently active.
         */
        const bool & get_can_select_when_inactive() const { return can_select_when_inactive; }
        bool & get_mutable_can_select_when_inactive() { return can_select_when_inactive; }
        void set_can_select_when_inactive(const bool & value) { this->can_select_when_inactive = value; }

        /**
         * Opacity of the layer (0 to 1.0)
         */
        const double & get_display_opacity() const { return display_opacity; }
        double & get_mutable_display_opacity() { return display_opacity; }
        void set_display_opacity(const double & value) { this->display_opacity = value; }

        /**
         * User defined documentation for this element to provide help/tips to level designers.
         */
        boost::optional<std::string> get_doc() const { return doc; }
        void set_doc(boost::optional<std::string> value) { this->doc = value; }

        /**
         * An array of tags to forbid some Entities in this layer
         */
        const std::vector<std::string> & get_excluded_tags() const { return excluded_tags; }
        std::vector<std::string> & get_mutable_excluded_tags() { return excluded_tags; }
        void set_excluded_tags(const std::vector<std::string> & value) { this->excluded_tags = value; }

        /**
         * Width and height of the grid in pixels
         */
        const int64_t & get_grid_size() const { return grid_size; }
        int64_t & get_mutable_grid_size() { return grid_size; }
        void set_grid_size(const int64_t & value) { this->grid_size = value; }

        /**
         * Height of the optional "guide" grid in pixels
         */
        const int64_t & get_guide_grid_hei() const { return guide_grid_hei; }
        int64_t & get_mutable_guide_grid_hei() { return guide_grid_hei; }
        void set_guide_grid_hei(const int64_t & value) { this->guide_grid_hei = value; }

        /**
         * Width of the optional "guide" grid in pixels
         */
        const int64_t & get_guide_grid_wid() const { return guide_grid_wid; }
        int64_t & get_mutable_guide_grid_wid() { return guide_grid_wid; }
        void set_guide_grid_wid(const int64_t & value) { this->guide_grid_wid = value; }

        const bool & get_hide_fields_when_inactive() const { return hide_fields_when_inactive; }
        bool & get_mutable_hide_fields_when_inactive() { return hide_fields_when_inactive; }
        void set_hide_fields_when_inactive(const bool & value) { this->hide_fields_when_inactive = value; }

        /**
         * Hide the layer from the list on the side of the editor view.
         */
        const bool & get_hide_in_list() const { return hide_in_list; }
        bool & get_mutable_hide_in_list() { return hide_in_list; }
        void set_hide_in_list(const bool & value) { this->hide_in_list = value; }

        /**
         * User defined unique identifier
         */
        const std::string & get_identifier() const { return identifier; }
        std::string & get_mutable_identifier() { return identifier; }
        void set_identifier(const std::string & value) { this->identifier = value; }

        /**
         * Alpha of this layer when it is not the active one.
         */
        const double & get_inactive_opacity() const { return inactive_opacity; }
        double & get_mutable_inactive_opacity() { return inactive_opacity; }
        void set_inactive_opacity(const double & value) { this->inactive_opacity = value; }

        /**
         * An array that defines extra optional info for each IntGrid value.<br/>  WARNING: the
         * array order is not related to actual IntGrid values! As user can re-order IntGrid values
         * freely, you may value "2" before value "1" in this array.
         */
        const std::vector<IntGridValueDefinition> & get_int_grid_values() const { return int_grid_values; }
        std::vector<IntGridValueDefinition> & get_mutable_int_grid_values() { return int_grid_values; }
        void set_int_grid_values(const std::vector<IntGridValueDefinition> & value) { this->int_grid_values = value; }

        /**
         * Group informations for IntGrid values
         */
        const std::vector<IntGridValueGroupDefinition> & get_int_grid_values_groups() const { return int_grid_values_groups; }
        std::vector<IntGridValueGroupDefinition> & get_mutable_int_grid_values_groups() { return int_grid_values_groups; }
        void set_int_grid_values_groups(const std::vector<IntGridValueGroupDefinition> & value) { this->int_grid_values_groups = value; }

        /**
         * Parallax horizontal factor (from -1 to 1, defaults to 0) which affects the scrolling
         * speed of this layer, creating a fake 3D (parallax) effect.
         */
        const double & get_parallax_factor_x() const { return parallax_factor_x; }
        double & get_mutable_parallax_factor_x() { return parallax_factor_x; }
        void set_parallax_factor_x(const double & value) { this->parallax_factor_x = value; }

        /**
         * Parallax vertical factor (from -1 to 1, defaults to 0) which affects the scrolling speed
         * of this layer, creating a fake 3D (parallax) effect.
         */
        const double & get_parallax_factor_y() const { return parallax_factor_y; }
        double & get_mutable_parallax_factor_y() { return parallax_factor_y; }
        void set_parallax_factor_y(const double & value) { this->parallax_factor_y = value; }

        /**
         * If true (default), a layer with a parallax factor will also be scaled up/down accordingly.
         */
        const bool & get_parallax_scaling() const { return parallax_scaling; }
        bool & get_mutable_parallax_scaling() { return parallax_scaling; }
        void set_parallax_scaling(const bool & value) { this->parallax_scaling = value; }

        /**
         * X offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance`
         * optional offset)
         */
        const int64_t & get_px_offset_x() const { return px_offset_x; }
        int64_t & get_mutable_px_offset_x() { return px_offset_x; }
        void set_px_offset_x(const int64_t & value) { this->px_offset_x = value; }

        /**
         * Y offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance`
         * optional offset)
         */
        const int64_t & get_px_offset_y() const { return px_offset_y; }
        int64_t & get_mutable_px_offset_y() { return px_offset_y; }
        void set_px_offset_y(const int64_t & value) { this->px_offset_y = value; }

        /**
         * If TRUE, the content of this layer will be used when rendering levels in a simplified way
         * for the world view
         */
        const bool & get_render_in_world_view() const { return render_in_world_view; }
        bool & get_mutable_render_in_world_view() { return render_in_world_view; }
        void set_render_in_world_view(const bool & value) { this->render_in_world_view = value; }

        /**
         * An array of tags to filter Entities that can be added to this layer
         */
        const std::vector<std::string> & get_required_tags() const { return required_tags; }
        std::vector<std::string> & get_mutable_required_tags() { return required_tags; }
        void set_required_tags(const std::vector<std::string> & value) { this->required_tags = value; }

        /**
         * If the tiles are smaller or larger than the layer grid, the pivot value will be used to
         * position the tile relatively its grid cell.
         */
        const double & get_tile_pivot_x() const { return tile_pivot_x; }
        double & get_mutable_tile_pivot_x() { return tile_pivot_x; }
        void set_tile_pivot_x(const double & value) { this->tile_pivot_x = value; }

        /**
         * If the tiles are smaller or larger than the layer grid, the pivot value will be used to
         * position the tile relatively its grid cell.
         */
        const double & get_tile_pivot_y() const { return tile_pivot_y; }
        double & get_mutable_tile_pivot_y() { return tile_pivot_y; }
        void set_tile_pivot_y(const double & value) { this->tile_pivot_y = value; }

        /**
         * Reference to the default Tileset UID being used by this layer definition.<br/>
         * **WARNING**: some layer *instances* might use a different tileset. So most of the time,
         * you should probably use the `__tilesetDefUid` value found in layer instances.<br/>  Note:
         * since version 1.0.0, the old `autoTilesetDefUid` was removed and merged into this value.
         */
        boost::optional<int64_t> get_tileset_def_uid() const { return tileset_def_uid; }
        void set_tileset_def_uid(boost::optional<int64_t> value) { this->tileset_def_uid = value; }

        /**
         * Type of the layer as Haxe Enum Possible values: `IntGrid`, `Entities`, `Tiles`,
         * `AutoLayer`
         */
        const Type & get_layer_definition_type() const { return layer_definition_type; }
        Type & get_mutable_layer_definition_type() { return layer_definition_type; }
        void set_layer_definition_type(const Type & value) { this->layer_definition_type = value; }

        /**
         * User defined color for the UI
         */
        boost::optional<std::string> get_ui_color() const { return ui_color; }
        void set_ui_color(boost::optional<std::string> value) { this->ui_color = value; }

        /**
         * Unique Int identifier
         */
        const int64_t & get_uid() const { return uid; }
        int64_t & get_mutable_uid() { return uid; }
        void set_uid(const int64_t & value) { this->uid = value; }
    };

    /**
     * In a tileset definition, user defined meta-data of a tile.
     */
    class TileCustomMetadata {
        public:
        TileCustomMetadata() = default;
        virtual ~TileCustomMetadata() = default;

        private:
        std::string data;
        int64_t tile_id;

        public:
        const std::string & get_data() const { return data; }
        std::string & get_mutable_data() { return data; }
        void set_data(const std::string & value) { this->data = value; }

        const int64_t & get_tile_id() const { return tile_id; }
        int64_t & get_mutable_tile_id() { return tile_id; }
        void set_tile_id(const int64_t & value) { this->tile_id = value; }
    };

    enum class EmbedAtlas : int { LDTK_ICONS };

    /**
     * In a tileset definition, enum based tag infos
     */
    class EnumTagValue {
        public:
        EnumTagValue() = default;
        virtual ~EnumTagValue() = default;

        private:
        std::string enum_value_id;
        std::vector<int64_t> tile_ids;

        public:
        const std::string & get_enum_value_id() const { return enum_value_id; }
        std::string & get_mutable_enum_value_id() { return enum_value_id; }
        void set_enum_value_id(const std::string & value) { this->enum_value_id = value; }

        const std::vector<int64_t> & get_tile_ids() const { return tile_ids; }
        std::vector<int64_t> & get_mutable_tile_ids() { return tile_ids; }
        void set_tile_ids(const std::vector<int64_t> & value) { this->tile_ids = value; }
    };

    /**
     * The `Tileset` definition is the most important part among project definitions. It
     * contains some extra informations about each integrated tileset. If you only had to parse
     * one definition section, that would be the one.
     */
    class TilesetDefinition {
        public:
        TilesetDefinition() = default;
        virtual ~TilesetDefinition() = default;

        private:
        int64_t c_hei;
        int64_t c_wid;
        boost::optional<std::map<std::string, nlohmann::json>> cached_pixel_data;
        std::vector<TileCustomMetadata> custom_data;
        boost::optional<EmbedAtlas> embed_atlas;
        std::vector<EnumTagValue> enum_tags;
        std::string identifier;
        int64_t padding;
        int64_t px_hei;
        int64_t px_wid;
        boost::optional<std::string> rel_path;
        std::vector<std::map<std::string, nlohmann::json>> saved_selections;
        int64_t spacing;
        std::vector<std::string> tags;
        boost::optional<int64_t> tags_source_enum_uid;
        int64_t tile_grid_size;
        int64_t uid;

        public:
        /**
         * Grid-based height
         */
        const int64_t & get_c_hei() const { return c_hei; }
        int64_t & get_mutable_c_hei() { return c_hei; }
        void set_c_hei(const int64_t & value) { this->c_hei = value; }

        /**
         * Grid-based width
         */
        const int64_t & get_c_wid() const { return c_wid; }
        int64_t & get_mutable_c_wid() { return c_wid; }
        void set_c_wid(const int64_t & value) { this->c_wid = value; }

        /**
         * The following data is used internally for various optimizations. It's always synced with
         * source image changes.
         */
        boost::optional<std::map<std::string, nlohmann::json>> get_cached_pixel_data() const { return cached_pixel_data; }
        void set_cached_pixel_data(boost::optional<std::map<std::string, nlohmann::json>> value) { this->cached_pixel_data = value; }

        /**
         * An array of custom tile metadata
         */
        const std::vector<TileCustomMetadata> & get_custom_data() const { return custom_data; }
        std::vector<TileCustomMetadata> & get_mutable_custom_data() { return custom_data; }
        void set_custom_data(const std::vector<TileCustomMetadata> & value) { this->custom_data = value; }

        /**
         * If this value is set, then it means that this atlas uses an internal LDtk atlas image
         * instead of a loaded one. Possible values: &lt;`null`&gt;, `LdtkIcons`
         */
        boost::optional<EmbedAtlas> get_embed_atlas() const { return embed_atlas; }
        void set_embed_atlas(boost::optional<EmbedAtlas> value) { this->embed_atlas = value; }

        /**
         * Tileset tags using Enum values specified by `tagsSourceEnumId`. This array contains 1
         * element per Enum value, which contains an array of all Tile IDs that are tagged with it.
         */
        const std::vector<EnumTagValue> & get_enum_tags() const { return enum_tags; }
        std::vector<EnumTagValue> & get_mutable_enum_tags() { return enum_tags; }
        void set_enum_tags(const std::vector<EnumTagValue> & value) { this->enum_tags = value; }

        /**
         * User defined unique identifier
         */
        const std::string & get_identifier() const { return identifier; }
        std::string & get_mutable_identifier() { return identifier; }
        void set_identifier(const std::string & value) { this->identifier = value; }

        /**
         * Distance in pixels from image borders
         */
        const int64_t & get_padding() const { return padding; }
        int64_t & get_mutable_padding() { return padding; }
        void set_padding(const int64_t & value) { this->padding = value; }

        /**
         * Image height in pixels
         */
        const int64_t & get_px_hei() const { return px_hei; }
        int64_t & get_mutable_px_hei() { return px_hei; }
        void set_px_hei(const int64_t & value) { this->px_hei = value; }

        /**
         * Image width in pixels
         */
        const int64_t & get_px_wid() const { return px_wid; }
        int64_t & get_mutable_px_wid() { return px_wid; }
        void set_px_wid(const int64_t & value) { this->px_wid = value; }

        /**
         * Path to the source file, relative to the current project JSON file<br/>  It can be null
         * if no image was provided, or when using an embed atlas.
         */
        boost::optional<std::string> get_rel_path() const { return rel_path; }
        void set_rel_path(boost::optional<std::string> value) { this->rel_path = value; }

        /**
         * Array of group of tiles selections, only meant to be used in the editor
         */
        const std::vector<std::map<std::string, nlohmann::json>> & get_saved_selections() const { return saved_selections; }
        std::vector<std::map<std::string, nlohmann::json>> & get_mutable_saved_selections() { return saved_selections; }
        void set_saved_selections(const std::vector<std::map<std::string, nlohmann::json>> & value) { this->saved_selections = value; }

        /**
         * Space in pixels between all tiles
         */
        const int64_t & get_spacing() const { return spacing; }
        int64_t & get_mutable_spacing() { return spacing; }
        void set_spacing(const int64_t & value) { this->spacing = value; }

        /**
         * An array of user-defined tags to organize the Tilesets
         */
        const std::vector<std::string> & get_tags() const { return tags; }
        std::vector<std::string> & get_mutable_tags() { return tags; }
        void set_tags(const std::vector<std::string> & value) { this->tags = value; }

        /**
         * Optional Enum definition UID used for this tileset meta-data
         */
        boost::optional<int64_t> get_tags_source_enum_uid() const { return tags_source_enum_uid; }
        void set_tags_source_enum_uid(boost::optional<int64_t> value) { this->tags_source_enum_uid = value; }

        const int64_t & get_tile_grid_size() const { return tile_grid_size; }
        int64_t & get_mutable_tile_grid_size() { return tile_grid_size; }
        void set_tile_grid_size(const int64_t & value) { this->tile_grid_size = value; }

        /**
         * Unique Intidentifier
         */
        const int64_t & get_uid() const { return uid; }
        int64_t & get_mutable_uid() { return uid; }
        void set_uid(const int64_t & value) { this->uid = value; }
    };

    /**
     * If you're writing your own LDtk importer, you should probably just ignore *most* stuff in
     * the `defs` section, as it contains data that are mostly important to the editor. To keep
     * you away from the `defs` section and avoid some unnecessary JSON parsing, important data
     * from definitions is often duplicated in fields prefixed with a double underscore (eg.
     * `__identifier` or `__type`).  The 2 only definition types you might need here are
     * **Tilesets** and **Enums**.
     *
     * A structure containing all the definitions of this project
     */
    class Definitions {
        public:
        Definitions() = default;
        virtual ~Definitions() = default;

        private:
        std::vector<EntityDefinition> entities;
        std::vector<EnumDefinition> enums;
        std::vector<EnumDefinition> external_enums;
        std::vector<LayerDefinition> layers;
        std::vector<FieldDefinition> level_fields;
        std::vector<TilesetDefinition> tilesets;

        public:
        /**
         * All entities definitions, including their custom fields
         */
        const std::vector<EntityDefinition> & get_entities() const { return entities; }
        std::vector<EntityDefinition> & get_mutable_entities() { return entities; }
        void set_entities(const std::vector<EntityDefinition> & value) { this->entities = value; }

        /**
         * All internal enums
         */
        const std::vector<EnumDefinition> & get_enums() const { return enums; }
        std::vector<EnumDefinition> & get_mutable_enums() { return enums; }
        void set_enums(const std::vector<EnumDefinition> & value) { this->enums = value; }

        /**
         * Note: external enums are exactly the same as `enums`, except they have a `relPath` to
         * point to an external source file.
         */
        const std::vector<EnumDefinition> & get_external_enums() const { return external_enums; }
        std::vector<EnumDefinition> & get_mutable_external_enums() { return external_enums; }
        void set_external_enums(const std::vector<EnumDefinition> & value) { this->external_enums = value; }

        /**
         * All layer definitions
         */
        const std::vector<LayerDefinition> & get_layers() const { return layers; }
        std::vector<LayerDefinition> & get_mutable_layers() { return layers; }
        void set_layers(const std::vector<LayerDefinition> & value) { this->layers = value; }

        /**
         * All custom fields available to all levels.
         */
        const std::vector<FieldDefinition> & get_level_fields() const { return level_fields; }
        std::vector<FieldDefinition> & get_mutable_level_fields() { return level_fields; }
        void set_level_fields(const std::vector<FieldDefinition> & value) { this->level_fields = value; }

        /**
         * All tilesets
         */
        const std::vector<TilesetDefinition> & get_tilesets() const { return tilesets; }
        std::vector<TilesetDefinition> & get_mutable_tilesets() { return tilesets; }
        void set_tilesets(const std::vector<TilesetDefinition> & value) { this->tilesets = value; }
    };

    enum class Flag : int { DISCARD_PRE_CSV_INT_GRID, EXPORT_PRE_CSV_INT_GRID_FORMAT, IGNORE_BACKUP_SUGGEST, MULTI_WORLDS, PREPEND_INDEX_TO_LEVEL_FILE_NAMES, USE_MULTILINES_TYPE };

    class FieldInstance {
        public:
        FieldInstance() = default;
        virtual ~FieldInstance() = default;

        private:
        std::string identifier;
        boost::optional<TilesetRectangle> tile;
        std::string type;
        nlohmann::json value;
        int64_t def_uid;
        std::vector<nlohmann::json> real_editor_values;

        public:
        /**
         * Field definition identifier
         */
        const std::string & get_identifier() const { return identifier; }
        std::string & get_mutable_identifier() { return identifier; }
        void set_identifier(const std::string & value) { this->identifier = value; }

        /**
         * Optional TilesetRect used to display this field (this can be the field own Tile, or some
         * other Tile guessed from the value, like an Enum).
         */
        boost::optional<TilesetRectangle> get_tile() const { return tile; }
        void set_tile(boost::optional<TilesetRectangle> value) { this->tile = value; }

        /**
         * Type of the field, such as `Int`, `Float`, `String`, `Enum(my_enum_name)`, `Bool`,
         * etc.<br/>  NOTE: if you enable the advanced option **Use Multilines type**, you will have
         * "*Multilines*" instead of "*String*" when relevant.
         */
        const std::string & get_type() const { return type; }
        std::string & get_mutable_type() { return type; }
        void set_type(const std::string & value) { this->type = value; }

        /**
         * Actual value of the field instance. The value type varies, depending on `__type`:<br/>
         * - For **classic types** (ie. Integer, Float, Boolean, String, Text and FilePath), you
         * just get the actual value with the expected type.<br/>   - For **Color**, the value is an
         * hexadecimal string using "#rrggbb" format.<br/>   - For **Enum**, the value is a String
         * representing the selected enum value.<br/>   - For **Point**, the value is a
         * [GridPoint](#ldtk-GridPoint) object.<br/>   - For **Tile**, the value is a
         * [TilesetRect](#ldtk-TilesetRect) object.<br/>   - For **EntityRef**, the value is an
         * [EntityReferenceInfos](#ldtk-EntityReferenceInfos) object.<br/><br/>  If the field is an
         * array, then this `__value` will also be a JSON array.
         */
        const nlohmann::json & get_value() const { return value; }
        nlohmann::json & get_mutable_value() { return value; }
        void set_value(const nlohmann::json & value) { this->value = value; }

        /**
         * Reference of the **Field definition** UID
         */
        const int64_t & get_def_uid() const { return def_uid; }
        int64_t & get_mutable_def_uid() { return def_uid; }
        void set_def_uid(const int64_t & value) { this->def_uid = value; }

        /**
         * Editor internal raw values
         */
        const std::vector<nlohmann::json> & get_real_editor_values() const { return real_editor_values; }
        std::vector<nlohmann::json> & get_mutable_real_editor_values() { return real_editor_values; }
        void set_real_editor_values(const std::vector<nlohmann::json> & value) { this->real_editor_values = value; }
    };

    class EntityInstance {
        public:
        EntityInstance() = default;
        virtual ~EntityInstance() = default;

        private:
        std::vector<int64_t> grid;
        std::string identifier;
        std::vector<double> pivot;
        std::string smart_color;
        std::vector<std::string> tags;
        boost::optional<TilesetRectangle> tile;
        int64_t world_x;
        int64_t world_y;
        int64_t def_uid;
        std::vector<FieldInstance> field_instances;
        int64_t height;
        std::string iid;
        std::vector<int64_t> px;
        int64_t width;

        public:
        /**
         * Grid-based coordinates (`[x,y]` format)
         */
        const std::vector<int64_t> & get_grid() const { return grid; }
        std::vector<int64_t> & get_mutable_grid() { return grid; }
        void set_grid(const std::vector<int64_t> & value) { this->grid = value; }

        /**
         * Entity definition identifier
         */
        const std::string & get_identifier() const { return identifier; }
        std::string & get_mutable_identifier() { return identifier; }
        void set_identifier(const std::string & value) { this->identifier = value; }

        /**
         * Pivot coordinates  (`[x,y]` format, values are from 0 to 1) of the Entity
         */
        const std::vector<double> & get_pivot() const { return pivot; }
        std::vector<double> & get_mutable_pivot() { return pivot; }
        void set_pivot(const std::vector<double> & value) { this->pivot = value; }

        /**
         * The entity "smart" color, guessed from either Entity definition, or one its field
         * instances.
         */
        const std::string & get_smart_color() const { return smart_color; }
        std::string & get_mutable_smart_color() { return smart_color; }
        void set_smart_color(const std::string & value) { this->smart_color = value; }

        /**
         * Array of tags defined in this Entity definition
         */
        const std::vector<std::string> & get_tags() const { return tags; }
        std::vector<std::string> & get_mutable_tags() { return tags; }
        void set_tags(const std::vector<std::string> & value) { this->tags = value; }

        /**
         * Optional TilesetRect used to display this entity (it could either be the default Entity
         * tile, or some tile provided by a field value, like an Enum).
         */
        boost::optional<TilesetRectangle> get_tile() const { return tile; }
        void set_tile(boost::optional<TilesetRectangle> value) { this->tile = value; }

        /**
         * X world coordinate in pixels
         */
        const int64_t & get_world_x() const { return world_x; }
        int64_t & get_mutable_world_x() { return world_x; }
        void set_world_x(const int64_t & value) { this->world_x = value; }

        /**
         * Y world coordinate in pixels
         */
        const int64_t & get_world_y() const { return world_y; }
        int64_t & get_mutable_world_y() { return world_y; }
        void set_world_y(const int64_t & value) { this->world_y = value; }

        /**
         * Reference of the **Entity definition** UID
         */
        const int64_t & get_def_uid() const { return def_uid; }
        int64_t & get_mutable_def_uid() { return def_uid; }
        void set_def_uid(const int64_t & value) { this->def_uid = value; }

        /**
         * An array of all custom fields and their values.
         */
        const std::vector<FieldInstance> & get_field_instances() const { return field_instances; }
        std::vector<FieldInstance> & get_mutable_field_instances() { return field_instances; }
        void set_field_instances(const std::vector<FieldInstance> & value) { this->field_instances = value; }

        /**
         * Entity height in pixels. For non-resizable entities, it will be the same as Entity
         * definition.
         */
        const int64_t & get_height() const { return height; }
        int64_t & get_mutable_height() { return height; }
        void set_height(const int64_t & value) { this->height = value; }

        /**
         * Unique instance identifier
         */
        const std::string & get_iid() const { return iid; }
        std::string & get_mutable_iid() { return iid; }
        void set_iid(const std::string & value) { this->iid = value; }

        /**
         * Pixel coordinates (`[x,y]` format) in current level coordinate space. Don't forget
         * optional layer offsets, if they exist!
         */
        const std::vector<int64_t> & get_px() const { return px; }
        std::vector<int64_t> & get_mutable_px() { return px; }
        void set_px(const std::vector<int64_t> & value) { this->px = value; }

        /**
         * Entity width in pixels. For non-resizable entities, it will be the same as Entity
         * definition.
         */
        const int64_t & get_width() const { return width; }
        int64_t & get_mutable_width() { return width; }
        void set_width(const int64_t & value) { this->width = value; }
    };

    /**
     * This object describes the "location" of an Entity instance in the project worlds.
     */
    class ReferenceToAnEntityInstance {
        public:
        ReferenceToAnEntityInstance() = default;
        virtual ~ReferenceToAnEntityInstance() = default;

        private:
        std::string entity_iid;
        std::string layer_iid;
        std::string level_iid;
        std::string world_iid;

        public:
        /**
         * IID of the refered EntityInstance
         */
        const std::string & get_entity_iid() const { return entity_iid; }
        std::string & get_mutable_entity_iid() { return entity_iid; }
        void set_entity_iid(const std::string & value) { this->entity_iid = value; }

        /**
         * IID of the LayerInstance containing the refered EntityInstance
         */
        const std::string & get_layer_iid() const { return layer_iid; }
        std::string & get_mutable_layer_iid() { return layer_iid; }
        void set_layer_iid(const std::string & value) { this->layer_iid = value; }

        /**
         * IID of the Level containing the refered EntityInstance
         */
        const std::string & get_level_iid() const { return level_iid; }
        std::string & get_mutable_level_iid() { return level_iid; }
        void set_level_iid(const std::string & value) { this->level_iid = value; }

        /**
         * IID of the World containing the refered EntityInstance
         */
        const std::string & get_world_iid() const { return world_iid; }
        std::string & get_mutable_world_iid() { return world_iid; }
        void set_world_iid(const std::string & value) { this->world_iid = value; }
    };

    /**
     * This object is just a grid-based coordinate used in Field values.
     */
    class GridPoint {
        public:
        GridPoint() = default;
        virtual ~GridPoint() = default;

        private:
        int64_t cx;
        int64_t cy;

        public:
        /**
         * X grid-based coordinate
         */
        const int64_t & get_cx() const { return cx; }
        int64_t & get_mutable_cx() { return cx; }
        void set_cx(const int64_t & value) { this->cx = value; }

        /**
         * Y grid-based coordinate
         */
        const int64_t & get_cy() const { return cy; }
        int64_t & get_mutable_cy() { return cy; }
        void set_cy(const int64_t & value) { this->cy = value; }
    };

    /**
     * IntGrid value instance
     */
    class IntGridValueInstance {
        public:
        IntGridValueInstance() = default;
        virtual ~IntGridValueInstance() = default;

        private:
        int64_t coord_id;
        int64_t v;

        public:
        /**
         * Coordinate ID in the layer grid
         */
        const int64_t & get_coord_id() const { return coord_id; }
        int64_t & get_mutable_coord_id() { return coord_id; }
        void set_coord_id(const int64_t & value) { this->coord_id = value; }

        /**
         * IntGrid value
         */
        const int64_t & get_v() const { return v; }
        int64_t & get_mutable_v() { return v; }
        void set_v(const int64_t & value) { this->v = value; }
    };

    /**
     * This structure represents a single tile from a given Tileset.
     */
    class TileInstance {
        public:
        TileInstance() = default;
        virtual ~TileInstance() = default;

        private:
        double a;
        std::vector<int64_t> d;
        int64_t f;
        std::vector<int64_t> px;
        std::vector<int64_t> src;
        int64_t t;

        public:
        /**
         * Alpha/opacity of the tile (0-1, defaults to 1)
         */
        const double & get_a() const { return a; }
        double & get_mutable_a() { return a; }
        void set_a(const double & value) { this->a = value; }

        /**
         * Internal data used by the editor.<br/>  For auto-layer tiles: `[ruleId, coordId]`.<br/>
         * For tile-layer tiles: `[coordId]`.
         */
        const std::vector<int64_t> & get_d() const { return d; }
        std::vector<int64_t> & get_mutable_d() { return d; }
        void set_d(const std::vector<int64_t> & value) { this->d = value; }

        /**
         * "Flip bits", a 2-bits integer to represent the mirror transformations of the tile.<br/>
         * - Bit 0 = X flip<br/>   - Bit 1 = Y flip<br/>   Examples: f=0 (no flip), f=1 (X flip
         * only), f=2 (Y flip only), f=3 (both flips)
         */
        const int64_t & get_f() const { return f; }
        int64_t & get_mutable_f() { return f; }
        void set_f(const int64_t & value) { this->f = value; }

        /**
         * Pixel coordinates of the tile in the **layer** (`[x,y]` format). Don't forget optional
         * layer offsets, if they exist!
         */
        const std::vector<int64_t> & get_px() const { return px; }
        std::vector<int64_t> & get_mutable_px() { return px; }
        void set_px(const std::vector<int64_t> & value) { this->px = value; }

        /**
         * Pixel coordinates of the tile in the **tileset** (`[x,y]` format)
         */
        const std::vector<int64_t> & get_src() const { return src; }
        std::vector<int64_t> & get_mutable_src() { return src; }
        void set_src(const std::vector<int64_t> & value) { this->src = value; }

        /**
         * The *Tile ID* in the corresponding tileset.
         */
        const int64_t & get_t() const { return t; }
        int64_t & get_mutable_t() { return t; }
        void set_t(const int64_t & value) { this->t = value; }
    };

    class LayerInstance {
        public:
        LayerInstance() = default;
        virtual ~LayerInstance() = default;

        private:
        int64_t c_hei;
        int64_t c_wid;
        int64_t grid_size;
        std::string identifier;
        double opacity;
        int64_t px_total_offset_x;
        int64_t px_total_offset_y;
        boost::optional<int64_t> tileset_def_uid;
        boost::optional<std::string> tileset_rel_path;
        std::string type;
        std::vector<TileInstance> auto_layer_tiles;
        std::vector<EntityInstance> entity_instances;
        std::vector<TileInstance> grid_tiles;
        std::string iid;
        boost::optional<std::vector<IntGridValueInstance>> int_grid;
        std::vector<int64_t> int_grid_csv;
        int64_t layer_def_uid;
        int64_t level_id;
        std::vector<int64_t> optional_rules;
        boost::optional<int64_t> override_tileset_uid;
        int64_t px_offset_x;
        int64_t px_offset_y;
        int64_t seed;
        bool visible;

        public:
        /**
         * Grid-based height
         */
        const int64_t & get_c_hei() const { return c_hei; }
        int64_t & get_mutable_c_hei() { return c_hei; }
        void set_c_hei(const int64_t & value) { this->c_hei = value; }

        /**
         * Grid-based width
         */
        const int64_t & get_c_wid() const { return c_wid; }
        int64_t & get_mutable_c_wid() { return c_wid; }
        void set_c_wid(const int64_t & value) { this->c_wid = value; }

        /**
         * Grid size
         */
        const int64_t & get_grid_size() const { return grid_size; }
        int64_t & get_mutable_grid_size() { return grid_size; }
        void set_grid_size(const int64_t & value) { this->grid_size = value; }

        /**
         * Layer definition identifier
         */
        const std::string & get_identifier() const { return identifier; }
        std::string & get_mutable_identifier() { return identifier; }
        void set_identifier(const std::string & value) { this->identifier = value; }

        /**
         * Layer opacity as Float [0-1]
         */
        const double & get_opacity() const { return opacity; }
        double & get_mutable_opacity() { return opacity; }
        void set_opacity(const double & value) { this->opacity = value; }

        /**
         * Total layer X pixel offset, including both instance and definition offsets.
         */
        const int64_t & get_px_total_offset_x() const { return px_total_offset_x; }
        int64_t & get_mutable_px_total_offset_x() { return px_total_offset_x; }
        void set_px_total_offset_x(const int64_t & value) { this->px_total_offset_x = value; }

        /**
         * Total layer Y pixel offset, including both instance and definition offsets.
         */
        const int64_t & get_px_total_offset_y() const { return px_total_offset_y; }
        int64_t & get_mutable_px_total_offset_y() { return px_total_offset_y; }
        void set_px_total_offset_y(const int64_t & value) { this->px_total_offset_y = value; }

        /**
         * The definition UID of corresponding Tileset, if any.
         */
        boost::optional<int64_t> get_tileset_def_uid() const { return tileset_def_uid; }
        void set_tileset_def_uid(boost::optional<int64_t> value) { this->tileset_def_uid = value; }

        /**
         * The relative path to corresponding Tileset, if any.
         */
        boost::optional<std::string> get_tileset_rel_path() const { return tileset_rel_path; }
        void set_tileset_rel_path(boost::optional<std::string> value) { this->tileset_rel_path = value; }

        /**
         * Layer type (possible values: IntGrid, Entities, Tiles or AutoLayer)
         */
        const std::string & get_type() const { return type; }
        std::string & get_mutable_type() { return type; }
        void set_type(const std::string & value) { this->type = value; }

        /**
         * An array containing all tiles generated by Auto-layer rules. The array is already sorted
         * in display order (ie. 1st tile is beneath 2nd, which is beneath 3rd etc.).<br/><br/>
         * Note: if multiple tiles are stacked in the same cell as the result of different rules,
         * all tiles behind opaque ones will be discarded.
         */
        const std::vector<TileInstance> & get_auto_layer_tiles() const { return auto_layer_tiles; }
        std::vector<TileInstance> & get_mutable_auto_layer_tiles() { return auto_layer_tiles; }
        void set_auto_layer_tiles(const std::vector<TileInstance> & value) { this->auto_layer_tiles = value; }

        const std::vector<EntityInstance> & get_entity_instances() const { return entity_instances; }
        std::vector<EntityInstance> & get_mutable_entity_instances() { return entity_instances; }
        void set_entity_instances(const std::vector<EntityInstance> & value) { this->entity_instances = value; }

        const std::vector<TileInstance> & get_grid_tiles() const { return grid_tiles; }
        std::vector<TileInstance> & get_mutable_grid_tiles() { return grid_tiles; }
        void set_grid_tiles(const std::vector<TileInstance> & value) { this->grid_tiles = value; }

        /**
         * Unique layer instance identifier
         */
        const std::string & get_iid() const { return iid; }
        std::string & get_mutable_iid() { return iid; }
        void set_iid(const std::string & value) { this->iid = value; }

        /**
         * **WARNING**: this deprecated value is no longer exported since version 1.0.0  Replaced
         * by: `intGridCsv`
         */
        boost::optional<std::vector<IntGridValueInstance>> get_int_grid() const { return int_grid; }
        void set_int_grid(boost::optional<std::vector<IntGridValueInstance>> value) { this->int_grid = value; }

        /**
         * A list of all values in the IntGrid layer, stored in CSV format (Comma Separated
         * Values).<br/>  Order is from left to right, and top to bottom (ie. first row from left to
         * right, followed by second row, etc).<br/>  `0` means "empty cell" and IntGrid values
         * start at 1.<br/>  The array size is `__cWid` x `__cHei` cells.
         */
        const std::vector<int64_t> & get_int_grid_csv() const { return int_grid_csv; }
        std::vector<int64_t> & get_mutable_int_grid_csv() { return int_grid_csv; }
        void set_int_grid_csv(const std::vector<int64_t> & value) { this->int_grid_csv = value; }

        /**
         * Reference the Layer definition UID
         */
        const int64_t & get_layer_def_uid() const { return layer_def_uid; }
        int64_t & get_mutable_layer_def_uid() { return layer_def_uid; }
        void set_layer_def_uid(const int64_t & value) { this->layer_def_uid = value; }

        /**
         * Reference to the UID of the level containing this layer instance
         */
        const int64_t & get_level_id() const { return level_id; }
        int64_t & get_mutable_level_id() { return level_id; }
        void set_level_id(const int64_t & value) { this->level_id = value; }

        /**
         * An Array containing the UIDs of optional rules that were enabled in this specific layer
         * instance.
         */
        const std::vector<int64_t> & get_optional_rules() const { return optional_rules; }
        std::vector<int64_t> & get_mutable_optional_rules() { return optional_rules; }
        void set_optional_rules(const std::vector<int64_t> & value) { this->optional_rules = value; }

        /**
         * This layer can use another tileset by overriding the tileset UID here.
         */
        boost::optional<int64_t> get_override_tileset_uid() const { return override_tileset_uid; }
        void set_override_tileset_uid(boost::optional<int64_t> value) { this->override_tileset_uid = value; }

        /**
         * X offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to
         * the `LayerDef` optional offset, so you should probably prefer using `__pxTotalOffsetX`
         * which contains the total offset value)
         */
        const int64_t & get_px_offset_x() const { return px_offset_x; }
        int64_t & get_mutable_px_offset_x() { return px_offset_x; }
        void set_px_offset_x(const int64_t & value) { this->px_offset_x = value; }

        /**
         * Y offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to
         * the `LayerDef` optional offset, so you should probably prefer using `__pxTotalOffsetX`
         * which contains the total offset value)
         */
        const int64_t & get_px_offset_y() const { return px_offset_y; }
        int64_t & get_mutable_px_offset_y() { return px_offset_y; }
        void set_px_offset_y(const int64_t & value) { this->px_offset_y = value; }

        /**
         * Random seed used for Auto-Layers rendering
         */
        const int64_t & get_seed() const { return seed; }
        int64_t & get_mutable_seed() { return seed; }
        void set_seed(const int64_t & value) { this->seed = value; }

        /**
         * Layer instance visibility
         */
        const bool & get_visible() const { return visible; }
        bool & get_mutable_visible() { return visible; }
        void set_visible(const bool & value) { this->visible = value; }
    };

    /**
     * Level background image position info
     */
    class LevelBackgroundPosition {
        public:
        LevelBackgroundPosition() = default;
        virtual ~LevelBackgroundPosition() = default;

        private:
        std::vector<double> crop_rect;
        std::vector<double> scale;
        std::vector<int64_t> top_left_px;

        public:
        /**
         * An array of 4 float values describing the cropped sub-rectangle of the displayed
         * background image. This cropping happens when original is larger than the level bounds.
         * Array format: `[ cropX, cropY, cropWidth, cropHeight ]`
         */
        const std::vector<double> & get_crop_rect() const { return crop_rect; }
        std::vector<double> & get_mutable_crop_rect() { return crop_rect; }
        void set_crop_rect(const std::vector<double> & value) { this->crop_rect = value; }

        /**
         * An array containing the `[scaleX,scaleY]` values of the **cropped** background image,
         * depending on `bgPos` option.
         */
        const std::vector<double> & get_scale() const { return scale; }
        std::vector<double> & get_mutable_scale() { return scale; }
        void set_scale(const std::vector<double> & value) { this->scale = value; }

        /**
         * An array containing the `[x,y]` pixel coordinates of the top-left corner of the
         * **cropped** background image, depending on `bgPos` option.
         */
        const std::vector<int64_t> & get_top_left_px() const { return top_left_px; }
        std::vector<int64_t> & get_mutable_top_left_px() { return top_left_px; }
        void set_top_left_px(const std::vector<int64_t> & value) { this->top_left_px = value; }
    };

    enum class BgPos : int { CONTAIN, COVER, COVER_DIRTY, REPEAT, UNSCALED };

    /**
     * Nearby level info
     */
    class NeighbourLevel {
        public:
        NeighbourLevel() = default;
        virtual ~NeighbourLevel() = default;

        private:
        std::string dir;
        std::string level_iid;
        boost::optional<int64_t> level_uid;

        public:
        /**
         * A single lowercase character tipping on the level location (`n`orth, `s`outh, `w`est,
         * `e`ast).<br/>  Since 1.3.5, this character value can also be `<` (neighbour depth is
         * lower), `>` (neighbour depth is greater) or `o` (levels overlap and share the same world
         * depth).
         */
        const std::string & get_dir() const { return dir; }
        std::string & get_mutable_dir() { return dir; }
        void set_dir(const std::string & value) { this->dir = value; }

        /**
         * Neighbour Instance Identifier
         */
        const std::string & get_level_iid() const { return level_iid; }
        std::string & get_mutable_level_iid() { return level_iid; }
        void set_level_iid(const std::string & value) { this->level_iid = value; }

        /**
         * **WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced
         * by: `levelIid`
         */
        boost::optional<int64_t> get_level_uid() const { return level_uid; }
        void set_level_uid(boost::optional<int64_t> value) { this->level_uid = value; }
    };

    /**
     * This section contains all the level data. It can be found in 2 distinct forms, depending
     * on Project current settings:  - If "*Separate level files*" is **disabled** (default):
     * full level data is *embedded* inside the main Project JSON file, - If "*Separate level
     * files*" is **enabled**: level data is stored in *separate* standalone `.ldtkl` files (one
     * per level). In this case, the main Project JSON file will still contain most level data,
     * except heavy sections, like the `layerInstances` array (which will be null). The
     * `externalRelPath` string points to the `ldtkl` file.  A `ldtkl` file is just a JSON file
     * containing exactly what is described below.
     */
    class Level {
        public:
        Level() = default;
        virtual ~Level() = default;

        private:
        std::string bg_color;
        boost::optional<LevelBackgroundPosition> bg_pos;
        std::vector<NeighbourLevel> neighbours;
        std::string smart_color;
        boost::optional<std::string> level_bg_color;
        double bg_pivot_x;
        double bg_pivot_y;
        boost::optional<BgPos> level_bg_pos;
        boost::optional<std::string> bg_rel_path;
        boost::optional<std::string> external_rel_path;
        std::vector<FieldInstance> field_instances;
        std::string identifier;
        std::string iid;
        boost::optional<std::vector<LayerInstance>> layer_instances;
        int64_t px_hei;
        int64_t px_wid;
        int64_t uid;
        bool use_auto_identifier;
        int64_t world_depth;
        int64_t world_x;
        int64_t world_y;

        public:
        /**
         * Background color of the level (same as `bgColor`, except the default value is
         * automatically used here if its value is `null`)
         */
        const std::string & get_bg_color() const { return bg_color; }
        std::string & get_mutable_bg_color() { return bg_color; }
        void set_bg_color(const std::string & value) { this->bg_color = value; }

        /**
         * Position informations of the background image, if there is one.
         */
        boost::optional<LevelBackgroundPosition> get_bg_pos() const { return bg_pos; }
        void set_bg_pos(boost::optional<LevelBackgroundPosition> value) { this->bg_pos = value; }

        /**
         * An array listing all other levels touching this one on the world map. Since 1.3.5, this
         * includes levels that overlap in the same world layer, or in nearby world layers.<br/>
         * Only relevant for world layouts where level spatial positioning is manual (ie. GridVania,
         * Free). For Horizontal and Vertical layouts, this array is always empty.
         */
        const std::vector<NeighbourLevel> & get_neighbours() const { return neighbours; }
        std::vector<NeighbourLevel> & get_mutable_neighbours() { return neighbours; }
        void set_neighbours(const std::vector<NeighbourLevel> & value) { this->neighbours = value; }

        /**
         * The "guessed" color for this level in the editor, decided using either the background
         * color or an existing custom field.
         */
        const std::string & get_smart_color() const { return smart_color; }
        std::string & get_mutable_smart_color() { return smart_color; }
        void set_smart_color(const std::string & value) { this->smart_color = value; }

        /**
         * Background color of the level. If `null`, the project `defaultLevelBgColor` should be
         * used.
         */
        boost::optional<std::string> get_level_bg_color() const { return level_bg_color; }
        void set_level_bg_color(boost::optional<std::string> value) { this->level_bg_color = value; }

        /**
         * Background image X pivot (0-1)
         */
        const double & get_bg_pivot_x() const { return bg_pivot_x; }
        double & get_mutable_bg_pivot_x() { return bg_pivot_x; }
        void set_bg_pivot_x(const double & value) { this->bg_pivot_x = value; }

        /**
         * Background image Y pivot (0-1)
         */
        const double & get_bg_pivot_y() const { return bg_pivot_y; }
        double & get_mutable_bg_pivot_y() { return bg_pivot_y; }
        void set_bg_pivot_y(const double & value) { this->bg_pivot_y = value; }

        /**
         * An enum defining the way the background image (if any) is positioned on the level. See
         * `__bgPos` for resulting position info. Possible values: &lt;`null`&gt;, `Unscaled`,
         * `Contain`, `Cover`, `CoverDirty`, `Repeat`
         */
        boost::optional<BgPos> get_level_bg_pos() const { return level_bg_pos; }
        void set_level_bg_pos(boost::optional<BgPos> value) { this->level_bg_pos = value; }

        /**
         * The *optional* relative path to the level background image.
         */
        boost::optional<std::string> get_bg_rel_path() const { return bg_rel_path; }
        void set_bg_rel_path(boost::optional<std::string> value) { this->bg_rel_path = value; }

        /**
         * This value is not null if the project option "*Save levels separately*" is enabled. In
         * this case, this **relative** path points to the level Json file.
         */
        boost::optional<std::string> get_external_rel_path() const { return external_rel_path; }
        void set_external_rel_path(boost::optional<std::string> value) { this->external_rel_path = value; }

        /**
         * An array containing this level custom field values.
         */
        const std::vector<FieldInstance> & get_field_instances() const { return field_instances; }
        std::vector<FieldInstance> & get_mutable_field_instances() { return field_instances; }
        void set_field_instances(const std::vector<FieldInstance> & value) { this->field_instances = value; }

        /**
         * User defined unique identifier
         */
        const std::string & get_identifier() const { return identifier; }
        std::string & get_mutable_identifier() { return identifier; }
        void set_identifier(const std::string & value) { this->identifier = value; }

        /**
         * Unique instance identifier
         */
        const std::string & get_iid() const { return iid; }
        std::string & get_mutable_iid() { return iid; }
        void set_iid(const std::string & value) { this->iid = value; }

        /**
         * An array containing all Layer instances. **IMPORTANT**: if the project option "*Save
         * levels separately*" is enabled, this field will be `null`.<br/>  This array is **sorted
         * in display order**: the 1st layer is the top-most and the last is behind.
         */
        boost::optional<std::vector<LayerInstance>> get_layer_instances() const { return layer_instances; }
        void set_layer_instances(boost::optional<std::vector<LayerInstance>> value) { this->layer_instances = value; }

        /**
         * Height of the level in pixels
         */
        const int64_t & get_px_hei() const { return px_hei; }
        int64_t & get_mutable_px_hei() { return px_hei; }
        void set_px_hei(const int64_t & value) { this->px_hei = value; }

        /**
         * Width of the level in pixels
         */
        const int64_t & get_px_wid() const { return px_wid; }
        int64_t & get_mutable_px_wid() { return px_wid; }
        void set_px_wid(const int64_t & value) { this->px_wid = value; }

        /**
         * Unique Int identifier
         */
        const int64_t & get_uid() const { return uid; }
        int64_t & get_mutable_uid() { return uid; }
        void set_uid(const int64_t & value) { this->uid = value; }

        /**
         * If TRUE, the level identifier will always automatically use the naming pattern as defined
         * in `Project.levelNamePattern`. Becomes FALSE if the identifier is manually modified by
         * user.
         */
        const bool & get_use_auto_identifier() const { return use_auto_identifier; }
        bool & get_mutable_use_auto_identifier() { return use_auto_identifier; }
        void set_use_auto_identifier(const bool & value) { this->use_auto_identifier = value; }

        /**
         * Index that represents the "depth" of the level in the world. Default is 0, greater means
         * "above", lower means "below".<br/>  This value is mostly used for display only and is
         * intended to make stacking of levels easier to manage.
         */
        const int64_t & get_world_depth() const { return world_depth; }
        int64_t & get_mutable_world_depth() { return world_depth; }
        void set_world_depth(const int64_t & value) { this->world_depth = value; }

        /**
         * World X coordinate in pixels.<br/>  Only relevant for world layouts where level spatial
         * positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the
         * value is always -1 here.
         */
        const int64_t & get_world_x() const { return world_x; }
        int64_t & get_mutable_world_x() { return world_x; }
        void set_world_x(const int64_t & value) { this->world_x = value; }

        /**
         * World Y coordinate in pixels.<br/>  Only relevant for world layouts where level spatial
         * positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the
         * value is always -1 here.
         */
        const int64_t & get_world_y() const { return world_y; }
        int64_t & get_mutable_world_y() { return world_y; }
        void set_world_y(const int64_t & value) { this->world_y = value; }
    };

    class LdtkTableOfContentEntry {
        public:
        LdtkTableOfContentEntry() = default;
        virtual ~LdtkTableOfContentEntry() = default;

        private:
        std::string identifier;
        std::vector<ReferenceToAnEntityInstance> instances;

        public:
        const std::string & get_identifier() const { return identifier; }
        std::string & get_mutable_identifier() { return identifier; }
        void set_identifier(const std::string & value) { this->identifier = value; }

        const std::vector<ReferenceToAnEntityInstance> & get_instances() const { return instances; }
        std::vector<ReferenceToAnEntityInstance> & get_mutable_instances() { return instances; }
        void set_instances(const std::vector<ReferenceToAnEntityInstance> & value) { this->instances = value; }
    };

    enum class WorldLayout : int { FREE, GRID_VANIA, LINEAR_HORIZONTAL, LINEAR_VERTICAL };

    /**
     * **IMPORTANT**: this type is available as a preview. You can rely on it to update your
     * importers, for when it will be officially available.  A World contains multiple levels,
     * and it has its own layout settings.
     */
    class World {
        public:
        World() = default;
        virtual ~World() = default;

        private:
        int64_t default_level_height;
        int64_t default_level_width;
        std::string identifier;
        std::string iid;
        std::vector<Level> levels;
        int64_t world_grid_height;
        int64_t world_grid_width;
        boost::optional<WorldLayout> world_layout;

        public:
        /**
         * Default new level height
         */
        const int64_t & get_default_level_height() const { return default_level_height; }
        int64_t & get_mutable_default_level_height() { return default_level_height; }
        void set_default_level_height(const int64_t & value) { this->default_level_height = value; }

        /**
         * Default new level width
         */
        const int64_t & get_default_level_width() const { return default_level_width; }
        int64_t & get_mutable_default_level_width() { return default_level_width; }
        void set_default_level_width(const int64_t & value) { this->default_level_width = value; }

        /**
         * User defined unique identifier
         */
        const std::string & get_identifier() const { return identifier; }
        std::string & get_mutable_identifier() { return identifier; }
        void set_identifier(const std::string & value) { this->identifier = value; }

        /**
         * Unique instance identifer
         */
        const std::string & get_iid() const { return iid; }
        std::string & get_mutable_iid() { return iid; }
        void set_iid(const std::string & value) { this->iid = value; }

        /**
         * All levels from this world. The order of this array is only relevant in
         * `LinearHorizontal` and `linearVertical` world layouts (see `worldLayout` value).
         * Otherwise, you should refer to the `worldX`,`worldY` coordinates of each Level.
         */
        const std::vector<Level> & get_levels() const { return levels; }
        std::vector<Level> & get_mutable_levels() { return levels; }
        void set_levels(const std::vector<Level> & value) { this->levels = value; }

        /**
         * Height of the world grid in pixels.
         */
        const int64_t & get_world_grid_height() const { return world_grid_height; }
        int64_t & get_mutable_world_grid_height() { return world_grid_height; }
        void set_world_grid_height(const int64_t & value) { this->world_grid_height = value; }

        /**
         * Width of the world grid in pixels.
         */
        const int64_t & get_world_grid_width() const { return world_grid_width; }
        int64_t & get_mutable_world_grid_width() { return world_grid_width; }
        void set_world_grid_width(const int64_t & value) { this->world_grid_width = value; }

        /**
         * An enum that describes how levels are organized in this project (ie. linearly or in a 2D
         * space). Possible values: `Free`, `GridVania`, `LinearHorizontal`, `LinearVertical`, `null`
         */
        boost::optional<WorldLayout> get_world_layout() const { return world_layout; }
        void set_world_layout(boost::optional<WorldLayout> value) { this->world_layout = value; }
    };

    /**
     * This object is not actually used by LDtk. It ONLY exists to force explicit references to
     * all types, to make sure QuickType finds them and integrate all of them. Otherwise,
     * Quicktype will drop types that are not explicitely used.
     */
    class ForcedRefs {
        public:
        ForcedRefs() = default;
        virtual ~ForcedRefs() = default;

        private:
        boost::optional<AutoLayerRuleGroup> auto_layer_rule_group;
        boost::optional<AutoLayerRuleDefinition> auto_rule_def;
        boost::optional<LdtkCustomCommand> custom_command;
        boost::optional<Definitions> definitions;
        boost::optional<EntityDefinition> entity_def;
        boost::optional<EntityInstance> entity_instance;
        boost::optional<ReferenceToAnEntityInstance> entity_reference_infos;
        boost::optional<EnumDefinition> enum_def;
        boost::optional<EnumValueDefinition> enum_def_values;
        boost::optional<EnumTagValue> enum_tag_value;
        boost::optional<FieldDefinition> field_def;
        boost::optional<FieldInstance> field_instance;
        boost::optional<GridPoint> grid_point;
        boost::optional<IntGridValueDefinition> int_grid_value_def;
        boost::optional<IntGridValueGroupDefinition> int_grid_value_group_def;
        boost::optional<IntGridValueInstance> int_grid_value_instance;
        boost::optional<LayerDefinition> layer_def;
        boost::optional<LayerInstance> layer_instance;
        boost::optional<Level> level;
        boost::optional<LevelBackgroundPosition> level_bg_pos_infos;
        boost::optional<NeighbourLevel> neighbour_level;
        boost::optional<LdtkTableOfContentEntry> table_of_content_entry;
        boost::optional<TileInstance> tile;
        boost::optional<TileCustomMetadata> tile_custom_metadata;
        boost::optional<TilesetDefinition> tileset_def;
        boost::optional<TilesetRectangle> tileset_rect;
        boost::optional<World> world;

        public:
        boost::optional<AutoLayerRuleGroup> get_auto_layer_rule_group() const { return auto_layer_rule_group; }
        void set_auto_layer_rule_group(boost::optional<AutoLayerRuleGroup> value) { this->auto_layer_rule_group = value; }

        boost::optional<AutoLayerRuleDefinition> get_auto_rule_def() const { return auto_rule_def; }
        void set_auto_rule_def(boost::optional<AutoLayerRuleDefinition> value) { this->auto_rule_def = value; }

        boost::optional<LdtkCustomCommand> get_custom_command() const { return custom_command; }
        void set_custom_command(boost::optional<LdtkCustomCommand> value) { this->custom_command = value; }

        boost::optional<Definitions> get_definitions() const { return definitions; }
        void set_definitions(boost::optional<Definitions> value) { this->definitions = value; }

        boost::optional<EntityDefinition> get_entity_def() const { return entity_def; }
        void set_entity_def(boost::optional<EntityDefinition> value) { this->entity_def = value; }

        boost::optional<EntityInstance> get_entity_instance() const { return entity_instance; }
        void set_entity_instance(boost::optional<EntityInstance> value) { this->entity_instance = value; }

        boost::optional<ReferenceToAnEntityInstance> get_entity_reference_infos() const { return entity_reference_infos; }
        void set_entity_reference_infos(boost::optional<ReferenceToAnEntityInstance> value) { this->entity_reference_infos = value; }

        boost::optional<EnumDefinition> get_enum_def() const { return enum_def; }
        void set_enum_def(boost::optional<EnumDefinition> value) { this->enum_def = value; }

        boost::optional<EnumValueDefinition> get_enum_def_values() const { return enum_def_values; }
        void set_enum_def_values(boost::optional<EnumValueDefinition> value) { this->enum_def_values = value; }

        boost::optional<EnumTagValue> get_enum_tag_value() const { return enum_tag_value; }
        void set_enum_tag_value(boost::optional<EnumTagValue> value) { this->enum_tag_value = value; }

        boost::optional<FieldDefinition> get_field_def() const { return field_def; }
        void set_field_def(boost::optional<FieldDefinition> value) { this->field_def = value; }

        boost::optional<FieldInstance> get_field_instance() const { return field_instance; }
        void set_field_instance(boost::optional<FieldInstance> value) { this->field_instance = value; }

        boost::optional<GridPoint> get_grid_point() const { return grid_point; }
        void set_grid_point(boost::optional<GridPoint> value) { this->grid_point = value; }

        boost::optional<IntGridValueDefinition> get_int_grid_value_def() const { return int_grid_value_def; }
        void set_int_grid_value_def(boost::optional<IntGridValueDefinition> value) { this->int_grid_value_def = value; }

        boost::optional<IntGridValueGroupDefinition> get_int_grid_value_group_def() const { return int_grid_value_group_def; }
        void set_int_grid_value_group_def(boost::optional<IntGridValueGroupDefinition> value) { this->int_grid_value_group_def = value; }

        boost::optional<IntGridValueInstance> get_int_grid_value_instance() const { return int_grid_value_instance; }
        void set_int_grid_value_instance(boost::optional<IntGridValueInstance> value) { this->int_grid_value_instance = value; }

        boost::optional<LayerDefinition> get_layer_def() const { return layer_def; }
        void set_layer_def(boost::optional<LayerDefinition> value) { this->layer_def = value; }

        boost::optional<LayerInstance> get_layer_instance() const { return layer_instance; }
        void set_layer_instance(boost::optional<LayerInstance> value) { this->layer_instance = value; }

        boost::optional<Level> get_level() const { return level; }
        void set_level(boost::optional<Level> value) { this->level = value; }

        boost::optional<LevelBackgroundPosition> get_level_bg_pos_infos() const { return level_bg_pos_infos; }
        void set_level_bg_pos_infos(boost::optional<LevelBackgroundPosition> value) { this->level_bg_pos_infos = value; }

        boost::optional<NeighbourLevel> get_neighbour_level() const { return neighbour_level; }
        void set_neighbour_level(boost::optional<NeighbourLevel> value) { this->neighbour_level = value; }

        boost::optional<LdtkTableOfContentEntry> get_table_of_content_entry() const { return table_of_content_entry; }
        void set_table_of_content_entry(boost::optional<LdtkTableOfContentEntry> value) { this->table_of_content_entry = value; }

        boost::optional<TileInstance> get_tile() const { return tile; }
        void set_tile(boost::optional<TileInstance> value) { this->tile = value; }

        boost::optional<TileCustomMetadata> get_tile_custom_metadata() const { return tile_custom_metadata; }
        void set_tile_custom_metadata(boost::optional<TileCustomMetadata> value) { this->tile_custom_metadata = value; }

        boost::optional<TilesetDefinition> get_tileset_def() const { return tileset_def; }
        void set_tileset_def(boost::optional<TilesetDefinition> value) { this->tileset_def = value; }

        boost::optional<TilesetRectangle> get_tileset_rect() const { return tileset_rect; }
        void set_tileset_rect(boost::optional<TilesetRectangle> value) { this->tileset_rect = value; }

        boost::optional<World> get_world() const { return world; }
        void set_world(boost::optional<World> value) { this->world = value; }
    };

    /**
     * Naming convention for Identifiers (first-letter uppercase, full uppercase etc.) Possible
     * values: `Capitalize`, `Uppercase`, `Lowercase`, `Free`
     */
    enum class IdentifierStyle : int { CAPITALIZE, FREE, LOWERCASE, UPPERCASE };

    /**
     * "Image export" option when saving project. Possible values: `None`, `OneImagePerLayer`,
     * `OneImagePerLevel`, `LayersAndLevels`
     */
    enum class ImageExportMode : int { LAYERS_AND_LEVELS, NONE, ONE_IMAGE_PER_LAYER, ONE_IMAGE_PER_LEVEL };

    /**
     * This file is a JSON schema of files created by LDtk level editor (https://ldtk.io).
     *
     * This is the root of any Project JSON file. It contains:  - the project settings, - an
     * array of levels, - a group of definitions (that can probably be safely ignored for most
     * users).
     */
    class LdtkJson {
        public:
        LdtkJson() = default;
        virtual ~LdtkJson() = default;

        private:
        boost::optional<ForcedRefs> forced_refs;
        double app_build_id;
        int64_t backup_limit;
        bool backup_on_save;
        boost::optional<std::string> backup_rel_path;
        std::string bg_color;
        std::vector<LdtkCustomCommand> custom_commands;
        int64_t default_entity_height;
        int64_t default_entity_width;
        int64_t default_grid_size;
        std::string default_level_bg_color;
        boost::optional<int64_t> default_level_height;
        boost::optional<int64_t> default_level_width;
        double default_pivot_x;
        double default_pivot_y;
        Definitions defs;
        std::string dummy_world_iid;
        bool export_level_bg;
        boost::optional<bool> export_png;
        bool export_tiled;
        bool external_levels;
        std::vector<Flag> flags;
        IdentifierStyle identifier_style;
        std::string iid;
        ImageExportMode image_export_mode;
        std::string json_version;
        std::string level_name_pattern;
        std::vector<Level> levels;
        bool minify_json;
        int64_t next_uid;
        boost::optional<std::string> png_file_pattern;
        bool simplified_export;
        std::vector<LdtkTableOfContentEntry> toc;
        boost::optional<std::string> tutorial_desc;
        boost::optional<int64_t> world_grid_height;
        boost::optional<int64_t> world_grid_width;
        boost::optional<WorldLayout> world_layout;
        std::vector<World> worlds;

        public:
        /**
         * This object is not actually used by LDtk. It ONLY exists to force explicit references to
         * all types, to make sure QuickType finds them and integrate all of them. Otherwise,
         * Quicktype will drop types that are not explicitely used.
         */
        boost::optional<ForcedRefs> get_forced_refs() const { return forced_refs; }
        void set_forced_refs(boost::optional<ForcedRefs> value) { this->forced_refs = value; }

        /**
         * LDtk application build identifier.<br/>  This is only used to identify the LDtk version
         * that generated this particular project file, which can be useful for specific bug fixing.
         * Note that the build identifier is just the date of the release, so it's not unique to
         * each user (one single global ID per LDtk public release), and as a result, completely
         * anonymous.
         */
        const double & get_app_build_id() const { return app_build_id; }
        double & get_mutable_app_build_id() { return app_build_id; }
        void set_app_build_id(const double & value) { this->app_build_id = value; }

        /**
         * Number of backup files to keep, if the `backupOnSave` is TRUE
         */
        const int64_t & get_backup_limit() const { return backup_limit; }
        int64_t & get_mutable_backup_limit() { return backup_limit; }
        void set_backup_limit(const int64_t & value) { this->backup_limit = value; }

        /**
         * If TRUE, an extra copy of the project will be created in a sub folder, when saving.
         */
        const bool & get_backup_on_save() const { return backup_on_save; }
        bool & get_mutable_backup_on_save() { return backup_on_save; }
        void set_backup_on_save(const bool & value) { this->backup_on_save = value; }

        /**
         * Target relative path to store backup files
         */
        boost::optional<std::string> get_backup_rel_path() const { return backup_rel_path; }
        void set_backup_rel_path(boost::optional<std::string> value) { this->backup_rel_path = value; }

        /**
         * Project background color
         */
        const std::string & get_bg_color() const { return bg_color; }
        std::string & get_mutable_bg_color() { return bg_color; }
        void set_bg_color(const std::string & value) { this->bg_color = value; }

        /**
         * An array of command lines that can be ran manually by the user
         */
        const std::vector<LdtkCustomCommand> & get_custom_commands() const { return custom_commands; }
        std::vector<LdtkCustomCommand> & get_mutable_custom_commands() { return custom_commands; }
        void set_custom_commands(const std::vector<LdtkCustomCommand> & value) { this->custom_commands = value; }

        /**
         * Default height for new entities
         */
        const int64_t & get_default_entity_height() const { return default_entity_height; }
        int64_t & get_mutable_default_entity_height() { return default_entity_height; }
        void set_default_entity_height(const int64_t & value) { this->default_entity_height = value; }

        /**
         * Default width for new entities
         */
        const int64_t & get_default_entity_width() const { return default_entity_width; }
        int64_t & get_mutable_default_entity_width() { return default_entity_width; }
        void set_default_entity_width(const int64_t & value) { this->default_entity_width = value; }

        /**
         * Default grid size for new layers
         */
        const int64_t & get_default_grid_size() const { return default_grid_size; }
        int64_t & get_mutable_default_grid_size() { return default_grid_size; }
        void set_default_grid_size(const int64_t & value) { this->default_grid_size = value; }

        /**
         * Default background color of levels
         */
        const std::string & get_default_level_bg_color() const { return default_level_bg_color; }
        std::string & get_mutable_default_level_bg_color() { return default_level_bg_color; }
        void set_default_level_bg_color(const std::string & value) { this->default_level_bg_color = value; }

        /**
         * **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
         * It will then be `null`. You can enable the Multi-worlds advanced project option to enable
         * the change immediately.<br/><br/>  Default new level height
         */
        boost::optional<int64_t> get_default_level_height() const { return default_level_height; }
        void set_default_level_height(boost::optional<int64_t> value) { this->default_level_height = value; }

        /**
         * **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
         * It will then be `null`. You can enable the Multi-worlds advanced project option to enable
         * the change immediately.<br/><br/>  Default new level width
         */
        boost::optional<int64_t> get_default_level_width() const { return default_level_width; }
        void set_default_level_width(boost::optional<int64_t> value) { this->default_level_width = value; }

        /**
         * Default X pivot (0 to 1) for new entities
         */
        const double & get_default_pivot_x() const { return default_pivot_x; }
        double & get_mutable_default_pivot_x() { return default_pivot_x; }
        void set_default_pivot_x(const double & value) { this->default_pivot_x = value; }

        /**
         * Default Y pivot (0 to 1) for new entities
         */
        const double & get_default_pivot_y() const { return default_pivot_y; }
        double & get_mutable_default_pivot_y() { return default_pivot_y; }
        void set_default_pivot_y(const double & value) { this->default_pivot_y = value; }

        /**
         * A structure containing all the definitions of this project
         */
        const Definitions & get_defs() const { return defs; }
        Definitions & get_mutable_defs() { return defs; }
        void set_defs(const Definitions & value) { this->defs = value; }

        /**
         * If the project isn't in MultiWorlds mode, this is the IID of the internal "dummy" World.
         */
        const std::string & get_dummy_world_iid() const { return dummy_world_iid; }
        std::string & get_mutable_dummy_world_iid() { return dummy_world_iid; }
        void set_dummy_world_iid(const std::string & value) { this->dummy_world_iid = value; }

        /**
         * If TRUE, the exported PNGs will include the level background (color or image).
         */
        const bool & get_export_level_bg() const { return export_level_bg; }
        bool & get_mutable_export_level_bg() { return export_level_bg; }
        void set_export_level_bg(const bool & value) { this->export_level_bg = value; }

        /**
         * **WARNING**: this deprecated value is no longer exported since version 0.9.3  Replaced
         * by: `imageExportMode`
         */
        boost::optional<bool> get_export_png() const { return export_png; }
        void set_export_png(boost::optional<bool> value) { this->export_png = value; }

        /**
         * If TRUE, a Tiled compatible file will also be generated along with the LDtk JSON file
         * (default is FALSE)
         */
        const bool & get_export_tiled() const { return export_tiled; }
        bool & get_mutable_export_tiled() { return export_tiled; }
        void set_export_tiled(const bool & value) { this->export_tiled = value; }

        /**
         * If TRUE, one file will be saved for the project (incl. all its definitions) and one file
         * in a sub-folder for each level.
         */
        const bool & get_external_levels() const { return external_levels; }
        bool & get_mutable_external_levels() { return external_levels; }
        void set_external_levels(const bool & value) { this->external_levels = value; }

        /**
         * An array containing various advanced flags (ie. options or other states). Possible
         * values: `DiscardPreCsvIntGrid`, `ExportPreCsvIntGridFormat`, `IgnoreBackupSuggest`,
         * `PrependIndexToLevelFileNames`, `MultiWorlds`, `UseMultilinesType`
         */
        const std::vector<Flag> & get_flags() const { return flags; }
        std::vector<Flag> & get_mutable_flags() { return flags; }
        void set_flags(const std::vector<Flag> & value) { this->flags = value; }

        /**
         * Naming convention for Identifiers (first-letter uppercase, full uppercase etc.) Possible
         * values: `Capitalize`, `Uppercase`, `Lowercase`, `Free`
         */
        const IdentifierStyle & get_identifier_style() const { return identifier_style; }
        IdentifierStyle & get_mutable_identifier_style() { return identifier_style; }
        void set_identifier_style(const IdentifierStyle & value) { this->identifier_style = value; }

        /**
         * Unique project identifier
         */
        const std::string & get_iid() const { return iid; }
        std::string & get_mutable_iid() { return iid; }
        void set_iid(const std::string & value) { this->iid = value; }

        /**
         * "Image export" option when saving project. Possible values: `None`, `OneImagePerLayer`,
         * `OneImagePerLevel`, `LayersAndLevels`
         */
        const ImageExportMode & get_image_export_mode() const { return image_export_mode; }
        ImageExportMode & get_mutable_image_export_mode() { return image_export_mode; }
        void set_image_export_mode(const ImageExportMode & value) { this->image_export_mode = value; }

        /**
         * File format version
         */
        const std::string & get_json_version() const { return json_version; }
        std::string & get_mutable_json_version() { return json_version; }
        void set_json_version(const std::string & value) { this->json_version = value; }

        /**
         * The default naming convention for level identifiers.
         */
        const std::string & get_level_name_pattern() const { return level_name_pattern; }
        std::string & get_mutable_level_name_pattern() { return level_name_pattern; }
        void set_level_name_pattern(const std::string & value) { this->level_name_pattern = value; }

        /**
         * All levels. The order of this array is only relevant in `LinearHorizontal` and
         * `linearVertical` world layouts (see `worldLayout` value).<br/>  Otherwise, you should
         * refer to the `worldX`,`worldY` coordinates of each Level.
         */
        const std::vector<Level> & get_levels() const { return levels; }
        std::vector<Level> & get_mutable_levels() { return levels; }
        void set_levels(const std::vector<Level> & value) { this->levels = value; }

        /**
         * If TRUE, the Json is partially minified (no indentation, nor line breaks, default is
         * FALSE)
         */
        const bool & get_minify_json() const { return minify_json; }
        bool & get_mutable_minify_json() { return minify_json; }
        void set_minify_json(const bool & value) { this->minify_json = value; }

        /**
         * Next Unique integer ID available
         */
        const int64_t & get_next_uid() const { return next_uid; }
        int64_t & get_mutable_next_uid() { return next_uid; }
        void set_next_uid(const int64_t & value) { this->next_uid = value; }

        /**
         * File naming pattern for exported PNGs
         */
        boost::optional<std::string> get_png_file_pattern() const { return png_file_pattern; }
        void set_png_file_pattern(boost::optional<std::string> value) { this->png_file_pattern = value; }

        /**
         * If TRUE, a very simplified will be generated on saving, for quicker & easier engine
         * integration.
         */
        const bool & get_simplified_export() const { return simplified_export; }
        bool & get_mutable_simplified_export() { return simplified_export; }
        void set_simplified_export(const bool & value) { this->simplified_export = value; }

        /**
         * All instances of entities that have their `exportToToc` flag enabled are listed in this
         * array.
         */
        const std::vector<LdtkTableOfContentEntry> & get_toc() const { return toc; }
        std::vector<LdtkTableOfContentEntry> & get_mutable_toc() { return toc; }
        void set_toc(const std::vector<LdtkTableOfContentEntry> & value) { this->toc = value; }

        /**
         * This optional description is used by LDtk Samples to show up some informations and
         * instructions.
         */
        boost::optional<std::string> get_tutorial_desc() const { return tutorial_desc; }
        void set_tutorial_desc(boost::optional<std::string> value) { this->tutorial_desc = value; }

        /**
         * **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
         * It will then be `null`. You can enable the Multi-worlds advanced project option to enable
         * the change immediately.<br/><br/>  Height of the world grid in pixels.
         */
        boost::optional<int64_t> get_world_grid_height() const { return world_grid_height; }
        void set_world_grid_height(boost::optional<int64_t> value) { this->world_grid_height = value; }

        /**
         * **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
         * It will then be `null`. You can enable the Multi-worlds advanced project option to enable
         * the change immediately.<br/><br/>  Width of the world grid in pixels.
         */
        boost::optional<int64_t> get_world_grid_width() const { return world_grid_width; }
        void set_world_grid_width(boost::optional<int64_t> value) { this->world_grid_width = value; }

        /**
         * **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
         * It will then be `null`. You can enable the Multi-worlds advanced project option to enable
         * the change immediately.<br/><br/>  An enum that describes how levels are organized in
         * this project (ie. linearly or in a 2D space). Possible values: &lt;`null`&gt;, `Free`,
         * `GridVania`, `LinearHorizontal`, `LinearVertical`
         */
        boost::optional<WorldLayout> get_world_layout() const { return world_layout; }
        void set_world_layout(boost::optional<WorldLayout> value) { this->world_layout = value; }

        /**
         * This array will be empty, unless you enable the Multi-Worlds in the project advanced
         * settings.<br/><br/> - in current version, a LDtk project file can only contain a single
         * world with multiple levels in it. In this case, levels and world layout related settings
         * are stored in the root of the JSON.<br/> - with "Multi-worlds" enabled, there will be a
         * `worlds` array in root, each world containing levels and layout settings. Basically, it's
         * pretty much only about moving the `levels` array to the `worlds` array, along with world
         * layout related values (eg. `worldGridWidth` etc).<br/><br/>If you want to start
         * supporting this future update easily, please refer to this documentation:
         * https://github.com/deepnight/ldtk/issues/231
         */
        const std::vector<World> & get_worlds() const { return worlds; }
        std::vector<World> & get_mutable_worlds() { return worlds; }
        void set_worlds(const std::vector<World> & value) { this->worlds = value; }
    };
}

namespace quicktype {
    void from_json(const json & j, LdtkCustomCommand & x);
    void to_json(json & j, const LdtkCustomCommand & x);

    void from_json(const json & j, FieldDefinition & x);
    void to_json(json & j, const FieldDefinition & x);

    void from_json(const json & j, TilesetRectangle & x);
    void to_json(json & j, const TilesetRectangle & x);

    void from_json(const json & j, EntityDefinition & x);
    void to_json(json & j, const EntityDefinition & x);

    void from_json(const json & j, EnumValueDefinition & x);
    void to_json(json & j, const EnumValueDefinition & x);

    void from_json(const json & j, EnumDefinition & x);
    void to_json(json & j, const EnumDefinition & x);

    void from_json(const json & j, AutoLayerRuleDefinition & x);
    void to_json(json & j, const AutoLayerRuleDefinition & x);

    void from_json(const json & j, AutoLayerRuleGroup & x);
    void to_json(json & j, const AutoLayerRuleGroup & x);

    void from_json(const json & j, IntGridValueDefinition & x);
    void to_json(json & j, const IntGridValueDefinition & x);

    void from_json(const json & j, IntGridValueGroupDefinition & x);
    void to_json(json & j, const IntGridValueGroupDefinition & x);

    void from_json(const json & j, LayerDefinition & x);
    void to_json(json & j, const LayerDefinition & x);

    void from_json(const json & j, TileCustomMetadata & x);
    void to_json(json & j, const TileCustomMetadata & x);

    void from_json(const json & j, EnumTagValue & x);
    void to_json(json & j, const EnumTagValue & x);

    void from_json(const json & j, TilesetDefinition & x);
    void to_json(json & j, const TilesetDefinition & x);

    void from_json(const json & j, Definitions & x);
    void to_json(json & j, const Definitions & x);

    void from_json(const json & j, FieldInstance & x);
    void to_json(json & j, const FieldInstance & x);

    void from_json(const json & j, EntityInstance & x);
    void to_json(json & j, const EntityInstance & x);

    void from_json(const json & j, ReferenceToAnEntityInstance & x);
    void to_json(json & j, const ReferenceToAnEntityInstance & x);

    void from_json(const json & j, GridPoint & x);
    void to_json(json & j, const GridPoint & x);

    void from_json(const json & j, IntGridValueInstance & x);
    void to_json(json & j, const IntGridValueInstance & x);

    void from_json(const json & j, TileInstance & x);
    void to_json(json & j, const TileInstance & x);

    void from_json(const json & j, LayerInstance & x);
    void to_json(json & j, const LayerInstance & x);

    void from_json(const json & j, LevelBackgroundPosition & x);
    void to_json(json & j, const LevelBackgroundPosition & x);

    void from_json(const json & j, NeighbourLevel & x);
    void to_json(json & j, const NeighbourLevel & x);

    void from_json(const json & j, Level & x);
    void to_json(json & j, const Level & x);

    void from_json(const json & j, LdtkTableOfContentEntry & x);
    void to_json(json & j, const LdtkTableOfContentEntry & x);

    void from_json(const json & j, World & x);
    void to_json(json & j, const World & x);

    void from_json(const json & j, ForcedRefs & x);
    void to_json(json & j, const ForcedRefs & x);

    void from_json(const json & j, LdtkJson & x);
    void to_json(json & j, const LdtkJson & x);

    void from_json(const json & j, When & x);
    void to_json(json & j, const When & x);

    void from_json(const json & j, AllowedRefs & x);
    void to_json(json & j, const AllowedRefs & x);

    void from_json(const json & j, EditorDisplayMode & x);
    void to_json(json & j, const EditorDisplayMode & x);

    void from_json(const json & j, EditorDisplayPos & x);
    void to_json(json & j, const EditorDisplayPos & x);

    void from_json(const json & j, EditorLinkStyle & x);
    void to_json(json & j, const EditorLinkStyle & x);

    void from_json(const json & j, TextLanguageMode & x);
    void to_json(json & j, const TextLanguageMode & x);

    void from_json(const json & j, LimitBehavior & x);
    void to_json(json & j, const LimitBehavior & x);

    void from_json(const json & j, LimitScope & x);
    void to_json(json & j, const LimitScope & x);

    void from_json(const json & j, RenderMode & x);
    void to_json(json & j, const RenderMode & x);

    void from_json(const json & j, TileRenderMode & x);
    void to_json(json & j, const TileRenderMode & x);

    void from_json(const json & j, Checker & x);
    void to_json(json & j, const Checker & x);

    void from_json(const json & j, TileMode & x);
    void to_json(json & j, const TileMode & x);

    void from_json(const json & j, Type & x);
    void to_json(json & j, const Type & x);

    void from_json(const json & j, EmbedAtlas & x);
    void to_json(json & j, const EmbedAtlas & x);

    void from_json(const json & j, Flag & x);
    void to_json(json & j, const Flag & x);

    void from_json(const json & j, BgPos & x);
    void to_json(json & j, const BgPos & x);

    void from_json(const json & j, WorldLayout & x);
    void to_json(json & j, const WorldLayout & x);

    void from_json(const json & j, IdentifierStyle & x);
    void to_json(json & j, const IdentifierStyle & x);

    void from_json(const json & j, ImageExportMode & x);
    void to_json(json & j, const ImageExportMode & x);

    inline void from_json(const json & j, LdtkCustomCommand& x) {
        x.set_command(j.at("command").get<std::string>());
        x.set_when(j.at("when").get<When>());
    }

    inline void to_json(json & j, const LdtkCustomCommand & x) {
        j = json::object();
        j["command"] = x.get_command();
        j["when"] = x.get_when();
    }

    inline void from_json(const json & j, FieldDefinition& x) {
        x.set_type(j.at("__type").get<std::string>());
        x.set_accept_file_types(get_stack_optional<std::vector<std::string>>(j, "acceptFileTypes"));
        x.set_allowed_refs(j.at("allowedRefs").get<AllowedRefs>());
        x.set_allowed_refs_entity_uid(get_stack_optional<int64_t>(j, "allowedRefsEntityUid"));
        x.set_allowed_ref_tags(j.at("allowedRefTags").get<std::vector<std::string>>());
        x.set_allow_out_of_level_ref(j.at("allowOutOfLevelRef").get<bool>());
        x.set_array_max_length(get_stack_optional<int64_t>(j, "arrayMaxLength"));
        x.set_array_min_length(get_stack_optional<int64_t>(j, "arrayMinLength"));
        x.set_auto_chain_ref(j.at("autoChainRef").get<bool>());
        x.set_can_be_null(j.at("canBeNull").get<bool>());
        x.set_default_override(get_untyped(j, "defaultOverride"));
        x.set_doc(get_stack_optional<std::string>(j, "doc"));
        x.set_editor_always_show(j.at("editorAlwaysShow").get<bool>());
        x.set_editor_cut_long_values(j.at("editorCutLongValues").get<bool>());
        x.set_editor_display_color(get_stack_optional<std::string>(j, "editorDisplayColor"));
        x.set_editor_display_mode(j.at("editorDisplayMode").get<EditorDisplayMode>());
        x.set_editor_display_pos(j.at("editorDisplayPos").get<EditorDisplayPos>());
        x.set_editor_display_scale(j.at("editorDisplayScale").get<double>());
        x.set_editor_link_style(j.at("editorLinkStyle").get<EditorLinkStyle>());
        x.set_editor_show_in_world(j.at("editorShowInWorld").get<bool>());
        x.set_editor_text_prefix(get_stack_optional<std::string>(j, "editorTextPrefix"));
        x.set_editor_text_suffix(get_stack_optional<std::string>(j, "editorTextSuffix"));
        x.set_identifier(j.at("identifier").get<std::string>());
        x.set_is_array(j.at("isArray").get<bool>());
        x.set_max(get_stack_optional<double>(j, "max"));
        x.set_min(get_stack_optional<double>(j, "min"));
        x.set_regex(get_stack_optional<std::string>(j, "regex"));
        x.set_symmetrical_ref(j.at("symmetricalRef").get<bool>());
        x.set_text_language_mode(get_stack_optional<TextLanguageMode>(j, "textLanguageMode"));
        x.set_tileset_uid(get_stack_optional<int64_t>(j, "tilesetUid"));
        x.set_field_definition_type(j.at("type").get<std::string>());
        x.set_uid(j.at("uid").get<int64_t>());
        x.set_use_for_smart_color(j.at("useForSmartColor").get<bool>());
    }

    inline void to_json(json & j, const FieldDefinition & x) {
        j = json::object();
        j["__type"] = x.get_type();
        j["acceptFileTypes"] = x.get_accept_file_types();
        j["allowedRefs"] = x.get_allowed_refs();
        j["allowedRefsEntityUid"] = x.get_allowed_refs_entity_uid();
        j["allowedRefTags"] = x.get_allowed_ref_tags();
        j["allowOutOfLevelRef"] = x.get_allow_out_of_level_ref();
        j["arrayMaxLength"] = x.get_array_max_length();
        j["arrayMinLength"] = x.get_array_min_length();
        j["autoChainRef"] = x.get_auto_chain_ref();
        j["canBeNull"] = x.get_can_be_null();
        j["defaultOverride"] = x.get_default_override();
        j["doc"] = x.get_doc();
        j["editorAlwaysShow"] = x.get_editor_always_show();
        j["editorCutLongValues"] = x.get_editor_cut_long_values();
        j["editorDisplayColor"] = x.get_editor_display_color();
        j["editorDisplayMode"] = x.get_editor_display_mode();
        j["editorDisplayPos"] = x.get_editor_display_pos();
        j["editorDisplayScale"] = x.get_editor_display_scale();
        j["editorLinkStyle"] = x.get_editor_link_style();
        j["editorShowInWorld"] = x.get_editor_show_in_world();
        j["editorTextPrefix"] = x.get_editor_text_prefix();
        j["editorTextSuffix"] = x.get_editor_text_suffix();
        j["identifier"] = x.get_identifier();
        j["isArray"] = x.get_is_array();
        j["max"] = x.get_max();
        j["min"] = x.get_min();
        j["regex"] = x.get_regex();
        j["symmetricalRef"] = x.get_symmetrical_ref();
        j["textLanguageMode"] = x.get_text_language_mode();
        j["tilesetUid"] = x.get_tileset_uid();
        j["type"] = x.get_field_definition_type();
        j["uid"] = x.get_uid();
        j["useForSmartColor"] = x.get_use_for_smart_color();
    }

    inline void from_json(const json & j, TilesetRectangle& x) {
        x.set_h(j.at("h").get<int64_t>());
        x.set_tileset_uid(j.at("tilesetUid").get<int64_t>());
        x.set_w(j.at("w").get<int64_t>());
        x.set_x(j.at("x").get<int64_t>());
        x.set_y(j.at("y").get<int64_t>());
    }

    inline void to_json(json & j, const TilesetRectangle & x) {
        j = json::object();
        j["h"] = x.get_h();
        j["tilesetUid"] = x.get_tileset_uid();
        j["w"] = x.get_w();
        j["x"] = x.get_x();
        j["y"] = x.get_y();
    }

    inline void from_json(const json & j, EntityDefinition& x) {
        x.set_color(j.at("color").get<std::string>());
        x.set_doc(get_stack_optional<std::string>(j, "doc"));
        x.set_export_to_toc(j.at("exportToToc").get<bool>());
        x.set_field_defs(j.at("fieldDefs").get<std::vector<FieldDefinition>>());
        x.set_fill_opacity(j.at("fillOpacity").get<double>());
        x.set_height(j.at("height").get<int64_t>());
        x.set_hollow(j.at("hollow").get<bool>());
        x.set_identifier(j.at("identifier").get<std::string>());
        x.set_keep_aspect_ratio(j.at("keepAspectRatio").get<bool>());
        x.set_limit_behavior(j.at("limitBehavior").get<LimitBehavior>());
        x.set_limit_scope(j.at("limitScope").get<LimitScope>());
        x.set_line_opacity(j.at("lineOpacity").get<double>());
        x.set_max_count(j.at("maxCount").get<int64_t>());
        x.set_max_height(get_stack_optional<int64_t>(j, "maxHeight"));
        x.set_max_width(get_stack_optional<int64_t>(j, "maxWidth"));
        x.set_min_height(get_stack_optional<int64_t>(j, "minHeight"));
        x.set_min_width(get_stack_optional<int64_t>(j, "minWidth"));
        x.set_nine_slice_borders(j.at("nineSliceBorders").get<std::vector<int64_t>>());
        x.set_pivot_x(j.at("pivotX").get<double>());
        x.set_pivot_y(j.at("pivotY").get<double>());
        x.set_render_mode(j.at("renderMode").get<RenderMode>());
        x.set_resizable_x(j.at("resizableX").get<bool>());
        x.set_resizable_y(j.at("resizableY").get<bool>());
        x.set_show_name(j.at("showName").get<bool>());
        x.set_tags(j.at("tags").get<std::vector<std::string>>());
        x.set_tile_id(get_stack_optional<int64_t>(j, "tileId"));
        x.set_tile_opacity(j.at("tileOpacity").get<double>());
        x.set_tile_rect(get_stack_optional<TilesetRectangle>(j, "tileRect"));
        x.set_tile_render_mode(j.at("tileRenderMode").get<TileRenderMode>());
        x.set_tileset_id(get_stack_optional<int64_t>(j, "tilesetId"));
        x.set_uid(j.at("uid").get<int64_t>());
        x.set_ui_tile_rect(get_stack_optional<TilesetRectangle>(j, "uiTileRect"));
        x.set_width(j.at("width").get<int64_t>());
    }

    inline void to_json(json & j, const EntityDefinition & x) {
        j = json::object();
        j["color"] = x.get_color();
        j["doc"] = x.get_doc();
        j["exportToToc"] = x.get_export_to_toc();
        j["fieldDefs"] = x.get_field_defs();
        j["fillOpacity"] = x.get_fill_opacity();
        j["height"] = x.get_height();
        j["hollow"] = x.get_hollow();
        j["identifier"] = x.get_identifier();
        j["keepAspectRatio"] = x.get_keep_aspect_ratio();
        j["limitBehavior"] = x.get_limit_behavior();
        j["limitScope"] = x.get_limit_scope();
        j["lineOpacity"] = x.get_line_opacity();
        j["maxCount"] = x.get_max_count();
        j["maxHeight"] = x.get_max_height();
        j["maxWidth"] = x.get_max_width();
        j["minHeight"] = x.get_min_height();
        j["minWidth"] = x.get_min_width();
        j["nineSliceBorders"] = x.get_nine_slice_borders();
        j["pivotX"] = x.get_pivot_x();
        j["pivotY"] = x.get_pivot_y();
        j["renderMode"] = x.get_render_mode();
        j["resizableX"] = x.get_resizable_x();
        j["resizableY"] = x.get_resizable_y();
        j["showName"] = x.get_show_name();
        j["tags"] = x.get_tags();
        j["tileId"] = x.get_tile_id();
        j["tileOpacity"] = x.get_tile_opacity();
        j["tileRect"] = x.get_tile_rect();
        j["tileRenderMode"] = x.get_tile_render_mode();
        j["tilesetId"] = x.get_tileset_id();
        j["uid"] = x.get_uid();
        j["uiTileRect"] = x.get_ui_tile_rect();
        j["width"] = x.get_width();
    }

    inline void from_json(const json & j, EnumValueDefinition& x) {
        x.set_tile_src_rect(get_stack_optional<std::vector<int64_t>>(j, "__tileSrcRect"));
        x.set_color(j.at("color").get<int64_t>());
        x.set_id(j.at("id").get<std::string>());
        x.set_tile_id(get_stack_optional<int64_t>(j, "tileId"));
        x.set_tile_rect(get_stack_optional<TilesetRectangle>(j, "tileRect"));
    }

    inline void to_json(json & j, const EnumValueDefinition & x) {
        j = json::object();
        j["__tileSrcRect"] = x.get_tile_src_rect();
        j["color"] = x.get_color();
        j["id"] = x.get_id();
        j["tileId"] = x.get_tile_id();
        j["tileRect"] = x.get_tile_rect();
    }

    inline void from_json(const json & j, EnumDefinition& x) {
        x.set_external_file_checksum(get_stack_optional<std::string>(j, "externalFileChecksum"));
        x.set_external_rel_path(get_stack_optional<std::string>(j, "externalRelPath"));
        x.set_icon_tileset_uid(get_stack_optional<int64_t>(j, "iconTilesetUid"));
        x.set_identifier(j.at("identifier").get<std::string>());
        x.set_tags(j.at("tags").get<std::vector<std::string>>());
        x.set_uid(j.at("uid").get<int64_t>());
        x.set_values(j.at("values").get<std::vector<EnumValueDefinition>>());
    }

    inline void to_json(json & j, const EnumDefinition & x) {
        j = json::object();
        j["externalFileChecksum"] = x.get_external_file_checksum();
        j["externalRelPath"] = x.get_external_rel_path();
        j["iconTilesetUid"] = x.get_icon_tileset_uid();
        j["identifier"] = x.get_identifier();
        j["tags"] = x.get_tags();
        j["uid"] = x.get_uid();
        j["values"] = x.get_values();
    }

    inline void from_json(const json & j, AutoLayerRuleDefinition& x) {
        x.set_active(j.at("active").get<bool>());
        x.set_alpha(j.at("alpha").get<double>());
        x.set_break_on_match(j.at("breakOnMatch").get<bool>());
        x.set_chance(j.at("chance").get<double>());
        x.set_checker(j.at("checker").get<Checker>());
        x.set_flip_x(j.at("flipX").get<bool>());
        x.set_flip_y(j.at("flipY").get<bool>());
        x.set_out_of_bounds_value(get_stack_optional<int64_t>(j, "outOfBoundsValue"));
        x.set_pattern(j.at("pattern").get<std::vector<int64_t>>());
        x.set_perlin_active(j.at("perlinActive").get<bool>());
        x.set_perlin_octaves(j.at("perlinOctaves").get<double>());
        x.set_perlin_scale(j.at("perlinScale").get<double>());
        x.set_perlin_seed(j.at("perlinSeed").get<double>());
        x.set_pivot_x(j.at("pivotX").get<double>());
        x.set_pivot_y(j.at("pivotY").get<double>());
        x.set_size(j.at("size").get<int64_t>());
        x.set_tile_ids(j.at("tileIds").get<std::vector<int64_t>>());
        x.set_tile_mode(j.at("tileMode").get<TileMode>());
        x.set_tile_random_x_max(j.at("tileRandomXMax").get<int64_t>());
        x.set_tile_random_x_min(j.at("tileRandomXMin").get<int64_t>());
        x.set_tile_random_y_max(j.at("tileRandomYMax").get<int64_t>());
        x.set_tile_random_y_min(j.at("tileRandomYMin").get<int64_t>());
        x.set_tile_x_offset(j.at("tileXOffset").get<int64_t>());
        x.set_tile_y_offset(j.at("tileYOffset").get<int64_t>());
        x.set_uid(j.at("uid").get<int64_t>());
        x.set_x_modulo(j.at("xModulo").get<int64_t>());
        x.set_x_offset(j.at("xOffset").get<int64_t>());
        x.set_y_modulo(j.at("yModulo").get<int64_t>());
        x.set_y_offset(j.at("yOffset").get<int64_t>());
    }

    inline void to_json(json & j, const AutoLayerRuleDefinition & x) {
        j = json::object();
        j["active"] = x.get_active();
        j["alpha"] = x.get_alpha();
        j["breakOnMatch"] = x.get_break_on_match();
        j["chance"] = x.get_chance();
        j["checker"] = x.get_checker();
        j["flipX"] = x.get_flip_x();
        j["flipY"] = x.get_flip_y();
        j["outOfBoundsValue"] = x.get_out_of_bounds_value();
        j["pattern"] = x.get_pattern();
        j["perlinActive"] = x.get_perlin_active();
        j["perlinOctaves"] = x.get_perlin_octaves();
        j["perlinScale"] = x.get_perlin_scale();
        j["perlinSeed"] = x.get_perlin_seed();
        j["pivotX"] = x.get_pivot_x();
        j["pivotY"] = x.get_pivot_y();
        j["size"] = x.get_size();
        j["tileIds"] = x.get_tile_ids();
        j["tileMode"] = x.get_tile_mode();
        j["tileRandomXMax"] = x.get_tile_random_x_max();
        j["tileRandomXMin"] = x.get_tile_random_x_min();
        j["tileRandomYMax"] = x.get_tile_random_y_max();
        j["tileRandomYMin"] = x.get_tile_random_y_min();
        j["tileXOffset"] = x.get_tile_x_offset();
        j["tileYOffset"] = x.get_tile_y_offset();
        j["uid"] = x.get_uid();
        j["xModulo"] = x.get_x_modulo();
        j["xOffset"] = x.get_x_offset();
        j["yModulo"] = x.get_y_modulo();
        j["yOffset"] = x.get_y_offset();
    }

    inline void from_json(const json & j, AutoLayerRuleGroup& x) {
        x.set_active(j.at("active").get<bool>());
        x.set_collapsed(get_stack_optional<bool>(j, "collapsed"));
        x.set_color(get_stack_optional<std::string>(j, "color"));
        x.set_icon(get_stack_optional<TilesetRectangle>(j, "icon"));
        x.set_is_optional(j.at("isOptional").get<bool>());
        x.set_name(j.at("name").get<std::string>());
        x.set_rules(j.at("rules").get<std::vector<AutoLayerRuleDefinition>>());
        x.set_uid(j.at("uid").get<int64_t>());
        x.set_uses_wizard(j.at("usesWizard").get<bool>());
    }

    inline void to_json(json & j, const AutoLayerRuleGroup & x) {
        j = json::object();
        j["active"] = x.get_active();
        j["collapsed"] = x.get_collapsed();
        j["color"] = x.get_color();
        j["icon"] = x.get_icon();
        j["isOptional"] = x.get_is_optional();
        j["name"] = x.get_name();
        j["rules"] = x.get_rules();
        j["uid"] = x.get_uid();
        j["usesWizard"] = x.get_uses_wizard();
    }

    inline void from_json(const json & j, IntGridValueDefinition& x) {
        x.set_color(j.at("color").get<std::string>());
        x.set_group_uid(j.at("groupUid").get<int64_t>());
        x.set_identifier(get_stack_optional<std::string>(j, "identifier"));
        x.set_tile(get_stack_optional<TilesetRectangle>(j, "tile"));
        x.set_value(j.at("value").get<int64_t>());
    }

    inline void to_json(json & j, const IntGridValueDefinition & x) {
        j = json::object();
        j["color"] = x.get_color();
        j["groupUid"] = x.get_group_uid();
        j["identifier"] = x.get_identifier();
        j["tile"] = x.get_tile();
        j["value"] = x.get_value();
    }

    inline void from_json(const json & j, IntGridValueGroupDefinition& x) {
        x.set_color(get_stack_optional<std::string>(j, "color"));
        x.set_identifier(get_stack_optional<std::string>(j, "identifier"));
        x.set_uid(j.at("uid").get<int64_t>());
    }

    inline void to_json(json & j, const IntGridValueGroupDefinition & x) {
        j = json::object();
        j["color"] = x.get_color();
        j["identifier"] = x.get_identifier();
        j["uid"] = x.get_uid();
    }

    inline void from_json(const json & j, LayerDefinition& x) {
        x.set_type(j.at("__type").get<std::string>());
        x.set_auto_rule_groups(j.at("autoRuleGroups").get<std::vector<AutoLayerRuleGroup>>());
        x.set_auto_source_layer_def_uid(get_stack_optional<int64_t>(j, "autoSourceLayerDefUid"));
        x.set_auto_tileset_def_uid(get_stack_optional<int64_t>(j, "autoTilesetDefUid"));
        x.set_can_select_when_inactive(j.at("canSelectWhenInactive").get<bool>());
        x.set_display_opacity(j.at("displayOpacity").get<double>());
        x.set_doc(get_stack_optional<std::string>(j, "doc"));
        x.set_excluded_tags(j.at("excludedTags").get<std::vector<std::string>>());
        x.set_grid_size(j.at("gridSize").get<int64_t>());
        x.set_guide_grid_hei(j.at("guideGridHei").get<int64_t>());
        x.set_guide_grid_wid(j.at("guideGridWid").get<int64_t>());
        x.set_hide_fields_when_inactive(j.at("hideFieldsWhenInactive").get<bool>());
        x.set_hide_in_list(j.at("hideInList").get<bool>());
        x.set_identifier(j.at("identifier").get<std::string>());
        x.set_inactive_opacity(j.at("inactiveOpacity").get<double>());
        x.set_int_grid_values(j.at("intGridValues").get<std::vector<IntGridValueDefinition>>());
        x.set_int_grid_values_groups(j.at("intGridValuesGroups").get<std::vector<IntGridValueGroupDefinition>>());
        x.set_parallax_factor_x(j.at("parallaxFactorX").get<double>());
        x.set_parallax_factor_y(j.at("parallaxFactorY").get<double>());
        x.set_parallax_scaling(j.at("parallaxScaling").get<bool>());
        x.set_px_offset_x(j.at("pxOffsetX").get<int64_t>());
        x.set_px_offset_y(j.at("pxOffsetY").get<int64_t>());
        x.set_render_in_world_view(j.at("renderInWorldView").get<bool>());
        x.set_required_tags(j.at("requiredTags").get<std::vector<std::string>>());
        x.set_tile_pivot_x(j.at("tilePivotX").get<double>());
        x.set_tile_pivot_y(j.at("tilePivotY").get<double>());
        x.set_tileset_def_uid(get_stack_optional<int64_t>(j, "tilesetDefUid"));
        x.set_layer_definition_type(j.at("type").get<Type>());
        x.set_ui_color(get_stack_optional<std::string>(j, "uiColor"));
        x.set_uid(j.at("uid").get<int64_t>());
    }

    inline void to_json(json & j, const LayerDefinition & x) {
        j = json::object();
        j["__type"] = x.get_type();
        j["autoRuleGroups"] = x.get_auto_rule_groups();
        j["autoSourceLayerDefUid"] = x.get_auto_source_layer_def_uid();
        j["autoTilesetDefUid"] = x.get_auto_tileset_def_uid();
        j["canSelectWhenInactive"] = x.get_can_select_when_inactive();
        j["displayOpacity"] = x.get_display_opacity();
        j["doc"] = x.get_doc();
        j["excludedTags"] = x.get_excluded_tags();
        j["gridSize"] = x.get_grid_size();
        j["guideGridHei"] = x.get_guide_grid_hei();
        j["guideGridWid"] = x.get_guide_grid_wid();
        j["hideFieldsWhenInactive"] = x.get_hide_fields_when_inactive();
        j["hideInList"] = x.get_hide_in_list();
        j["identifier"] = x.get_identifier();
        j["inactiveOpacity"] = x.get_inactive_opacity();
        j["intGridValues"] = x.get_int_grid_values();
        j["intGridValuesGroups"] = x.get_int_grid_values_groups();
        j["parallaxFactorX"] = x.get_parallax_factor_x();
        j["parallaxFactorY"] = x.get_parallax_factor_y();
        j["parallaxScaling"] = x.get_parallax_scaling();
        j["pxOffsetX"] = x.get_px_offset_x();
        j["pxOffsetY"] = x.get_px_offset_y();
        j["renderInWorldView"] = x.get_render_in_world_view();
        j["requiredTags"] = x.get_required_tags();
        j["tilePivotX"] = x.get_tile_pivot_x();
        j["tilePivotY"] = x.get_tile_pivot_y();
        j["tilesetDefUid"] = x.get_tileset_def_uid();
        j["type"] = x.get_layer_definition_type();
        j["uiColor"] = x.get_ui_color();
        j["uid"] = x.get_uid();
    }

    inline void from_json(const json & j, TileCustomMetadata& x) {
        x.set_data(j.at("data").get<std::string>());
        x.set_tile_id(j.at("tileId").get<int64_t>());
    }

    inline void to_json(json & j, const TileCustomMetadata & x) {
        j = json::object();
        j["data"] = x.get_data();
        j["tileId"] = x.get_tile_id();
    }

    inline void from_json(const json & j, EnumTagValue& x) {
        x.set_enum_value_id(j.at("enumValueId").get<std::string>());
        x.set_tile_ids(j.at("tileIds").get<std::vector<int64_t>>());
    }

    inline void to_json(json & j, const EnumTagValue & x) {
        j = json::object();
        j["enumValueId"] = x.get_enum_value_id();
        j["tileIds"] = x.get_tile_ids();
    }

    inline void from_json(const json & j, TilesetDefinition& x) {
        x.set_c_hei(j.at("__cHei").get<int64_t>());
        x.set_c_wid(j.at("__cWid").get<int64_t>());
        x.set_cached_pixel_data(get_stack_optional<std::map<std::string, nlohmann::json>>(j, "cachedPixelData"));
        x.set_custom_data(j.at("customData").get<std::vector<TileCustomMetadata>>());
        x.set_embed_atlas(get_stack_optional<EmbedAtlas>(j, "embedAtlas"));
        x.set_enum_tags(j.at("enumTags").get<std::vector<EnumTagValue>>());
        x.set_identifier(j.at("identifier").get<std::string>());
        x.set_padding(j.at("padding").get<int64_t>());
        x.set_px_hei(j.at("pxHei").get<int64_t>());
        x.set_px_wid(j.at("pxWid").get<int64_t>());
        x.set_rel_path(get_stack_optional<std::string>(j, "relPath"));
        x.set_saved_selections(j.at("savedSelections").get<std::vector<std::map<std::string, nlohmann::json>>>());
        x.set_spacing(j.at("spacing").get<int64_t>());
        x.set_tags(j.at("tags").get<std::vector<std::string>>());
        x.set_tags_source_enum_uid(get_stack_optional<int64_t>(j, "tagsSourceEnumUid"));
        x.set_tile_grid_size(j.at("tileGridSize").get<int64_t>());
        x.set_uid(j.at("uid").get<int64_t>());
    }

    inline void to_json(json & j, const TilesetDefinition & x) {
        j = json::object();
        j["__cHei"] = x.get_c_hei();
        j["__cWid"] = x.get_c_wid();
        j["cachedPixelData"] = x.get_cached_pixel_data();
        j["customData"] = x.get_custom_data();
        j["embedAtlas"] = x.get_embed_atlas();
        j["enumTags"] = x.get_enum_tags();
        j["identifier"] = x.get_identifier();
        j["padding"] = x.get_padding();
        j["pxHei"] = x.get_px_hei();
        j["pxWid"] = x.get_px_wid();
        j["relPath"] = x.get_rel_path();
        j["savedSelections"] = x.get_saved_selections();
        j["spacing"] = x.get_spacing();
        j["tags"] = x.get_tags();
        j["tagsSourceEnumUid"] = x.get_tags_source_enum_uid();
        j["tileGridSize"] = x.get_tile_grid_size();
        j["uid"] = x.get_uid();
    }

    inline void from_json(const json & j, Definitions& x) {
        x.set_entities(j.at("entities").get<std::vector<EntityDefinition>>());
        x.set_enums(j.at("enums").get<std::vector<EnumDefinition>>());
        x.set_external_enums(j.at("externalEnums").get<std::vector<EnumDefinition>>());
        x.set_layers(j.at("layers").get<std::vector<LayerDefinition>>());
        x.set_level_fields(j.at("levelFields").get<std::vector<FieldDefinition>>());
        x.set_tilesets(j.at("tilesets").get<std::vector<TilesetDefinition>>());
    }

    inline void to_json(json & j, const Definitions & x) {
        j = json::object();
        j["entities"] = x.get_entities();
        j["enums"] = x.get_enums();
        j["externalEnums"] = x.get_external_enums();
        j["layers"] = x.get_layers();
        j["levelFields"] = x.get_level_fields();
        j["tilesets"] = x.get_tilesets();
    }

    inline void from_json(const json & j, FieldInstance& x) {
        x.set_identifier(j.at("__identifier").get<std::string>());
        x.set_tile(get_stack_optional<TilesetRectangle>(j, "__tile"));
        x.set_type(j.at("__type").get<std::string>());
        x.set_value(get_untyped(j, "__value"));
        x.set_def_uid(j.at("defUid").get<int64_t>());
        x.set_real_editor_values(j.at("realEditorValues").get<std::vector<nlohmann::json>>());
    }

    inline void to_json(json & j, const FieldInstance & x) {
        j = json::object();
        j["__identifier"] = x.get_identifier();
        j["__tile"] = x.get_tile();
        j["__type"] = x.get_type();
        j["__value"] = x.get_value();
        j["defUid"] = x.get_def_uid();
        j["realEditorValues"] = x.get_real_editor_values();
    }

    inline void from_json(const json & j, EntityInstance& x) {
        x.set_grid(j.at("__grid").get<std::vector<int64_t>>());
        x.set_identifier(j.at("__identifier").get<std::string>());
        x.set_pivot(j.at("__pivot").get<std::vector<double>>());
        x.set_smart_color(j.at("__smartColor").get<std::string>());
        x.set_tags(j.at("__tags").get<std::vector<std::string>>());
        x.set_tile(get_stack_optional<TilesetRectangle>(j, "__tile"));
        x.set_world_x(j.at("__worldX").get<int64_t>());
        x.set_world_y(j.at("__worldY").get<int64_t>());
        x.set_def_uid(j.at("defUid").get<int64_t>());
        x.set_field_instances(j.at("fieldInstances").get<std::vector<FieldInstance>>());
        x.set_height(j.at("height").get<int64_t>());
        x.set_iid(j.at("iid").get<std::string>());
        x.set_px(j.at("px").get<std::vector<int64_t>>());
        x.set_width(j.at("width").get<int64_t>());
    }

    inline void to_json(json & j, const EntityInstance & x) {
        j = json::object();
        j["__grid"] = x.get_grid();
        j["__identifier"] = x.get_identifier();
        j["__pivot"] = x.get_pivot();
        j["__smartColor"] = x.get_smart_color();
        j["__tags"] = x.get_tags();
        j["__tile"] = x.get_tile();
        j["__worldX"] = x.get_world_x();
        j["__worldY"] = x.get_world_y();
        j["defUid"] = x.get_def_uid();
        j["fieldInstances"] = x.get_field_instances();
        j["height"] = x.get_height();
        j["iid"] = x.get_iid();
        j["px"] = x.get_px();
        j["width"] = x.get_width();
    }

    inline void from_json(const json & j, ReferenceToAnEntityInstance& x) {
        x.set_entity_iid(j.at("entityIid").get<std::string>());
        x.set_layer_iid(j.at("layerIid").get<std::string>());
        x.set_level_iid(j.at("levelIid").get<std::string>());
        x.set_world_iid(j.at("worldIid").get<std::string>());
    }

    inline void to_json(json & j, const ReferenceToAnEntityInstance & x) {
        j = json::object();
        j["entityIid"] = x.get_entity_iid();
        j["layerIid"] = x.get_layer_iid();
        j["levelIid"] = x.get_level_iid();
        j["worldIid"] = x.get_world_iid();
    }

    inline void from_json(const json & j, GridPoint& x) {
        x.set_cx(j.at("cx").get<int64_t>());
        x.set_cy(j.at("cy").get<int64_t>());
    }

    inline void to_json(json & j, const GridPoint & x) {
        j = json::object();
        j["cx"] = x.get_cx();
        j["cy"] = x.get_cy();
    }

    inline void from_json(const json & j, IntGridValueInstance& x) {
        x.set_coord_id(j.at("coordId").get<int64_t>());
        x.set_v(j.at("v").get<int64_t>());
    }

    inline void to_json(json & j, const IntGridValueInstance & x) {
        j = json::object();
        j["coordId"] = x.get_coord_id();
        j["v"] = x.get_v();
    }

    inline void from_json(const json & j, TileInstance& x) {
        x.set_a(j.at("a").get<double>());
        x.set_d(j.at("d").get<std::vector<int64_t>>());
        x.set_f(j.at("f").get<int64_t>());
        x.set_px(j.at("px").get<std::vector<int64_t>>());
        x.set_src(j.at("src").get<std::vector<int64_t>>());
        x.set_t(j.at("t").get<int64_t>());
    }

    inline void to_json(json & j, const TileInstance & x) {
        j = json::object();
        j["a"] = x.get_a();
        j["d"] = x.get_d();
        j["f"] = x.get_f();
        j["px"] = x.get_px();
        j["src"] = x.get_src();
        j["t"] = x.get_t();
    }

    inline void from_json(const json & j, LayerInstance& x) {
        x.set_c_hei(j.at("__cHei").get<int64_t>());
        x.set_c_wid(j.at("__cWid").get<int64_t>());
        x.set_grid_size(j.at("__gridSize").get<int64_t>());
        x.set_identifier(j.at("__identifier").get<std::string>());
        x.set_opacity(j.at("__opacity").get<double>());
        x.set_px_total_offset_x(j.at("__pxTotalOffsetX").get<int64_t>());
        x.set_px_total_offset_y(j.at("__pxTotalOffsetY").get<int64_t>());
        x.set_tileset_def_uid(get_stack_optional<int64_t>(j, "__tilesetDefUid"));
        x.set_tileset_rel_path(get_stack_optional<std::string>(j, "__tilesetRelPath"));
        x.set_type(j.at("__type").get<std::string>());
        x.set_auto_layer_tiles(j.at("autoLayerTiles").get<std::vector<TileInstance>>());
        x.set_entity_instances(j.at("entityInstances").get<std::vector<EntityInstance>>());
        x.set_grid_tiles(j.at("gridTiles").get<std::vector<TileInstance>>());
        x.set_iid(j.at("iid").get<std::string>());
        x.set_int_grid(get_stack_optional<std::vector<IntGridValueInstance>>(j, "intGrid"));
        x.set_int_grid_csv(j.at("intGridCsv").get<std::vector<int64_t>>());
        x.set_layer_def_uid(j.at("layerDefUid").get<int64_t>());
        x.set_level_id(j.at("levelId").get<int64_t>());
        x.set_optional_rules(j.at("optionalRules").get<std::vector<int64_t>>());
        x.set_override_tileset_uid(get_stack_optional<int64_t>(j, "overrideTilesetUid"));
        x.set_px_offset_x(j.at("pxOffsetX").get<int64_t>());
        x.set_px_offset_y(j.at("pxOffsetY").get<int64_t>());
        x.set_seed(j.at("seed").get<int64_t>());
        x.set_visible(j.at("visible").get<bool>());
    }

    inline void to_json(json & j, const LayerInstance & x) {
        j = json::object();
        j["__cHei"] = x.get_c_hei();
        j["__cWid"] = x.get_c_wid();
        j["__gridSize"] = x.get_grid_size();
        j["__identifier"] = x.get_identifier();
        j["__opacity"] = x.get_opacity();
        j["__pxTotalOffsetX"] = x.get_px_total_offset_x();
        j["__pxTotalOffsetY"] = x.get_px_total_offset_y();
        j["__tilesetDefUid"] = x.get_tileset_def_uid();
        j["__tilesetRelPath"] = x.get_tileset_rel_path();
        j["__type"] = x.get_type();
        j["autoLayerTiles"] = x.get_auto_layer_tiles();
        j["entityInstances"] = x.get_entity_instances();
        j["gridTiles"] = x.get_grid_tiles();
        j["iid"] = x.get_iid();
        j["intGrid"] = x.get_int_grid();
        j["intGridCsv"] = x.get_int_grid_csv();
        j["layerDefUid"] = x.get_layer_def_uid();
        j["levelId"] = x.get_level_id();
        j["optionalRules"] = x.get_optional_rules();
        j["overrideTilesetUid"] = x.get_override_tileset_uid();
        j["pxOffsetX"] = x.get_px_offset_x();
        j["pxOffsetY"] = x.get_px_offset_y();
        j["seed"] = x.get_seed();
        j["visible"] = x.get_visible();
    }

    inline void from_json(const json & j, LevelBackgroundPosition& x) {
        x.set_crop_rect(j.at("cropRect").get<std::vector<double>>());
        x.set_scale(j.at("scale").get<std::vector<double>>());
        x.set_top_left_px(j.at("topLeftPx").get<std::vector<int64_t>>());
    }

    inline void to_json(json & j, const LevelBackgroundPosition & x) {
        j = json::object();
        j["cropRect"] = x.get_crop_rect();
        j["scale"] = x.get_scale();
        j["topLeftPx"] = x.get_top_left_px();
    }

    inline void from_json(const json & j, NeighbourLevel& x) {
        x.set_dir(j.at("dir").get<std::string>());
        x.set_level_iid(j.at("levelIid").get<std::string>());
        x.set_level_uid(get_stack_optional<int64_t>(j, "levelUid"));
    }

    inline void to_json(json & j, const NeighbourLevel & x) {
        j = json::object();
        j["dir"] = x.get_dir();
        j["levelIid"] = x.get_level_iid();
        j["levelUid"] = x.get_level_uid();
    }

    inline void from_json(const json & j, Level& x) {
        x.set_bg_color(j.at("__bgColor").get<std::string>());
        x.set_bg_pos(get_stack_optional<LevelBackgroundPosition>(j, "__bgPos"));
        x.set_neighbours(j.at("__neighbours").get<std::vector<NeighbourLevel>>());
        x.set_smart_color(j.at("__smartColor").get<std::string>());
        x.set_level_bg_color(get_stack_optional<std::string>(j, "bgColor"));
        x.set_bg_pivot_x(j.at("bgPivotX").get<double>());
        x.set_bg_pivot_y(j.at("bgPivotY").get<double>());
        x.set_level_bg_pos(get_stack_optional<BgPos>(j, "bgPos"));
        x.set_bg_rel_path(get_stack_optional<std::string>(j, "bgRelPath"));
        x.set_external_rel_path(get_stack_optional<std::string>(j, "externalRelPath"));
        x.set_field_instances(j.at("fieldInstances").get<std::vector<FieldInstance>>());
        x.set_identifier(j.at("identifier").get<std::string>());
        x.set_iid(j.at("iid").get<std::string>());
        x.set_layer_instances(get_stack_optional<std::vector<LayerInstance>>(j, "layerInstances"));
        x.set_px_hei(j.at("pxHei").get<int64_t>());
        x.set_px_wid(j.at("pxWid").get<int64_t>());
        x.set_uid(j.at("uid").get<int64_t>());
        x.set_use_auto_identifier(j.at("useAutoIdentifier").get<bool>());
        x.set_world_depth(j.at("worldDepth").get<int64_t>());
        x.set_world_x(j.at("worldX").get<int64_t>());
        x.set_world_y(j.at("worldY").get<int64_t>());
    }

    inline void to_json(json & j, const Level & x) {
        j = json::object();
        j["__bgColor"] = x.get_bg_color();
        j["__bgPos"] = x.get_bg_pos();
        j["__neighbours"] = x.get_neighbours();
        j["__smartColor"] = x.get_smart_color();
        j["bgColor"] = x.get_level_bg_color();
        j["bgPivotX"] = x.get_bg_pivot_x();
        j["bgPivotY"] = x.get_bg_pivot_y();
        j["bgPos"] = x.get_level_bg_pos();
        j["bgRelPath"] = x.get_bg_rel_path();
        j["externalRelPath"] = x.get_external_rel_path();
        j["fieldInstances"] = x.get_field_instances();
        j["identifier"] = x.get_identifier();
        j["iid"] = x.get_iid();
        j["layerInstances"] = x.get_layer_instances();
        j["pxHei"] = x.get_px_hei();
        j["pxWid"] = x.get_px_wid();
        j["uid"] = x.get_uid();
        j["useAutoIdentifier"] = x.get_use_auto_identifier();
        j["worldDepth"] = x.get_world_depth();
        j["worldX"] = x.get_world_x();
        j["worldY"] = x.get_world_y();
    }

    inline void from_json(const json & j, LdtkTableOfContentEntry& x) {
        x.set_identifier(j.at("identifier").get<std::string>());
        x.set_instances(j.at("instances").get<std::vector<ReferenceToAnEntityInstance>>());
    }

    inline void to_json(json & j, const LdtkTableOfContentEntry & x) {
        j = json::object();
        j["identifier"] = x.get_identifier();
        j["instances"] = x.get_instances();
    }

    inline void from_json(const json & j, World& x) {
        x.set_default_level_height(j.at("defaultLevelHeight").get<int64_t>());
        x.set_default_level_width(j.at("defaultLevelWidth").get<int64_t>());
        x.set_identifier(j.at("identifier").get<std::string>());
        x.set_iid(j.at("iid").get<std::string>());
        x.set_levels(j.at("levels").get<std::vector<Level>>());
        x.set_world_grid_height(j.at("worldGridHeight").get<int64_t>());
        x.set_world_grid_width(j.at("worldGridWidth").get<int64_t>());
        x.set_world_layout(get_stack_optional<WorldLayout>(j, "worldLayout"));
    }

    inline void to_json(json & j, const World & x) {
        j = json::object();
        j["defaultLevelHeight"] = x.get_default_level_height();
        j["defaultLevelWidth"] = x.get_default_level_width();
        j["identifier"] = x.get_identifier();
        j["iid"] = x.get_iid();
        j["levels"] = x.get_levels();
        j["worldGridHeight"] = x.get_world_grid_height();
        j["worldGridWidth"] = x.get_world_grid_width();
        j["worldLayout"] = x.get_world_layout();
    }

    inline void from_json(const json & j, ForcedRefs& x) {
        x.set_auto_layer_rule_group(get_stack_optional<AutoLayerRuleGroup>(j, "AutoLayerRuleGroup"));
        x.set_auto_rule_def(get_stack_optional<AutoLayerRuleDefinition>(j, "AutoRuleDef"));
        x.set_custom_command(get_stack_optional<LdtkCustomCommand>(j, "CustomCommand"));
        x.set_definitions(get_stack_optional<Definitions>(j, "Definitions"));
        x.set_entity_def(get_stack_optional<EntityDefinition>(j, "EntityDef"));
        x.set_entity_instance(get_stack_optional<EntityInstance>(j, "EntityInstance"));
        x.set_entity_reference_infos(get_stack_optional<ReferenceToAnEntityInstance>(j, "EntityReferenceInfos"));
        x.set_enum_def(get_stack_optional<EnumDefinition>(j, "EnumDef"));
        x.set_enum_def_values(get_stack_optional<EnumValueDefinition>(j, "EnumDefValues"));
        x.set_enum_tag_value(get_stack_optional<EnumTagValue>(j, "EnumTagValue"));
        x.set_field_def(get_stack_optional<FieldDefinition>(j, "FieldDef"));
        x.set_field_instance(get_stack_optional<FieldInstance>(j, "FieldInstance"));
        x.set_grid_point(get_stack_optional<GridPoint>(j, "GridPoint"));
        x.set_int_grid_value_def(get_stack_optional<IntGridValueDefinition>(j, "IntGridValueDef"));
        x.set_int_grid_value_group_def(get_stack_optional<IntGridValueGroupDefinition>(j, "IntGridValueGroupDef"));
        x.set_int_grid_value_instance(get_stack_optional<IntGridValueInstance>(j, "IntGridValueInstance"));
        x.set_layer_def(get_stack_optional<LayerDefinition>(j, "LayerDef"));
        x.set_layer_instance(get_stack_optional<LayerInstance>(j, "LayerInstance"));
        x.set_level(get_stack_optional<Level>(j, "Level"));
        x.set_level_bg_pos_infos(get_stack_optional<LevelBackgroundPosition>(j, "LevelBgPosInfos"));
        x.set_neighbour_level(get_stack_optional<NeighbourLevel>(j, "NeighbourLevel"));
        x.set_table_of_content_entry(get_stack_optional<LdtkTableOfContentEntry>(j, "TableOfContentEntry"));
        x.set_tile(get_stack_optional<TileInstance>(j, "Tile"));
        x.set_tile_custom_metadata(get_stack_optional<TileCustomMetadata>(j, "TileCustomMetadata"));
        x.set_tileset_def(get_stack_optional<TilesetDefinition>(j, "TilesetDef"));
        x.set_tileset_rect(get_stack_optional<TilesetRectangle>(j, "TilesetRect"));
        x.set_world(get_stack_optional<World>(j, "World"));
    }

    inline void to_json(json & j, const ForcedRefs & x) {
        j = json::object();
        j["AutoLayerRuleGroup"] = x.get_auto_layer_rule_group();
        j["AutoRuleDef"] = x.get_auto_rule_def();
        j["CustomCommand"] = x.get_custom_command();
        j["Definitions"] = x.get_definitions();
        j["EntityDef"] = x.get_entity_def();
        j["EntityInstance"] = x.get_entity_instance();
        j["EntityReferenceInfos"] = x.get_entity_reference_infos();
        j["EnumDef"] = x.get_enum_def();
        j["EnumDefValues"] = x.get_enum_def_values();
        j["EnumTagValue"] = x.get_enum_tag_value();
        j["FieldDef"] = x.get_field_def();
        j["FieldInstance"] = x.get_field_instance();
        j["GridPoint"] = x.get_grid_point();
        j["IntGridValueDef"] = x.get_int_grid_value_def();
        j["IntGridValueGroupDef"] = x.get_int_grid_value_group_def();
        j["IntGridValueInstance"] = x.get_int_grid_value_instance();
        j["LayerDef"] = x.get_layer_def();
        j["LayerInstance"] = x.get_layer_instance();
        j["Level"] = x.get_level();
        j["LevelBgPosInfos"] = x.get_level_bg_pos_infos();
        j["NeighbourLevel"] = x.get_neighbour_level();
        j["TableOfContentEntry"] = x.get_table_of_content_entry();
        j["Tile"] = x.get_tile();
        j["TileCustomMetadata"] = x.get_tile_custom_metadata();
        j["TilesetDef"] = x.get_tileset_def();
        j["TilesetRect"] = x.get_tileset_rect();
        j["World"] = x.get_world();
    }

    inline void from_json(const json & j, LdtkJson& x) {
        x.set_forced_refs(get_stack_optional<ForcedRefs>(j, "__FORCED_REFS"));
        x.set_app_build_id(j.at("appBuildId").get<double>());
        x.set_backup_limit(j.at("backupLimit").get<int64_t>());
        x.set_backup_on_save(j.at("backupOnSave").get<bool>());
        x.set_backup_rel_path(get_stack_optional<std::string>(j, "backupRelPath"));
        x.set_bg_color(j.at("bgColor").get<std::string>());
        x.set_custom_commands(j.at("customCommands").get<std::vector<LdtkCustomCommand>>());
        x.set_default_entity_height(j.at("defaultEntityHeight").get<int64_t>());
        x.set_default_entity_width(j.at("defaultEntityWidth").get<int64_t>());
        x.set_default_grid_size(j.at("defaultGridSize").get<int64_t>());
        x.set_default_level_bg_color(j.at("defaultLevelBgColor").get<std::string>());
        x.set_default_level_height(get_stack_optional<int64_t>(j, "defaultLevelHeight"));
        x.set_default_level_width(get_stack_optional<int64_t>(j, "defaultLevelWidth"));
        x.set_default_pivot_x(j.at("defaultPivotX").get<double>());
        x.set_default_pivot_y(j.at("defaultPivotY").get<double>());
        x.set_defs(j.at("defs").get<Definitions>());
        x.set_dummy_world_iid(j.at("dummyWorldIid").get<std::string>());
        x.set_export_level_bg(j.at("exportLevelBg").get<bool>());
        x.set_export_png(get_stack_optional<bool>(j, "exportPng"));
        x.set_export_tiled(j.at("exportTiled").get<bool>());
        x.set_external_levels(j.at("externalLevels").get<bool>());
        x.set_flags(j.at("flags").get<std::vector<Flag>>());
        x.set_identifier_style(j.at("identifierStyle").get<IdentifierStyle>());
        x.set_iid(j.at("iid").get<std::string>());
        x.set_image_export_mode(j.at("imageExportMode").get<ImageExportMode>());
        x.set_json_version(j.at("jsonVersion").get<std::string>());
        x.set_level_name_pattern(j.at("levelNamePattern").get<std::string>());
        x.set_levels(j.at("levels").get<std::vector<Level>>());
        x.set_minify_json(j.at("minifyJson").get<bool>());
        x.set_next_uid(j.at("nextUid").get<int64_t>());
        x.set_png_file_pattern(get_stack_optional<std::string>(j, "pngFilePattern"));
        x.set_simplified_export(j.at("simplifiedExport").get<bool>());
        x.set_toc(j.at("toc").get<std::vector<LdtkTableOfContentEntry>>());
        x.set_tutorial_desc(get_stack_optional<std::string>(j, "tutorialDesc"));
        x.set_world_grid_height(get_stack_optional<int64_t>(j, "worldGridHeight"));
        x.set_world_grid_width(get_stack_optional<int64_t>(j, "worldGridWidth"));
        x.set_world_layout(get_stack_optional<WorldLayout>(j, "worldLayout"));
        x.set_worlds(j.at("worlds").get<std::vector<World>>());
    }

    inline void to_json(json & j, const LdtkJson & x) {
        j = json::object();
        j["__FORCED_REFS"] = x.get_forced_refs();
        j["appBuildId"] = x.get_app_build_id();
        j["backupLimit"] = x.get_backup_limit();
        j["backupOnSave"] = x.get_backup_on_save();
        j["backupRelPath"] = x.get_backup_rel_path();
        j["bgColor"] = x.get_bg_color();
        j["customCommands"] = x.get_custom_commands();
        j["defaultEntityHeight"] = x.get_default_entity_height();
        j["defaultEntityWidth"] = x.get_default_entity_width();
        j["defaultGridSize"] = x.get_default_grid_size();
        j["defaultLevelBgColor"] = x.get_default_level_bg_color();
        j["defaultLevelHeight"] = x.get_default_level_height();
        j["defaultLevelWidth"] = x.get_default_level_width();
        j["defaultPivotX"] = x.get_default_pivot_x();
        j["defaultPivotY"] = x.get_default_pivot_y();
        j["defs"] = x.get_defs();
        j["dummyWorldIid"] = x.get_dummy_world_iid();
        j["exportLevelBg"] = x.get_export_level_bg();
        j["exportPng"] = x.get_export_png();
        j["exportTiled"] = x.get_export_tiled();
        j["externalLevels"] = x.get_external_levels();
        j["flags"] = x.get_flags();
        j["identifierStyle"] = x.get_identifier_style();
        j["iid"] = x.get_iid();
        j["imageExportMode"] = x.get_image_export_mode();
        j["jsonVersion"] = x.get_json_version();
        j["levelNamePattern"] = x.get_level_name_pattern();
        j["levels"] = x.get_levels();
        j["minifyJson"] = x.get_minify_json();
        j["nextUid"] = x.get_next_uid();
        j["pngFilePattern"] = x.get_png_file_pattern();
        j["simplifiedExport"] = x.get_simplified_export();
        j["toc"] = x.get_toc();
        j["tutorialDesc"] = x.get_tutorial_desc();
        j["worldGridHeight"] = x.get_world_grid_height();
        j["worldGridWidth"] = x.get_world_grid_width();
        j["worldLayout"] = x.get_world_layout();
        j["worlds"] = x.get_worlds();
    }

    inline void from_json(const json & j, When & x) {
        if (j == "AfterLoad") x = When::AFTER_LOAD;
        else if (j == "AfterSave") x = When::AFTER_SAVE;
        else if (j == "BeforeSave") x = When::BEFORE_SAVE;
        else if (j == "Manual") x = When::MANUAL;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const When & x) {
        switch (x) {
            case When::AFTER_LOAD: j = "AfterLoad"; break;
            case When::AFTER_SAVE: j = "AfterSave"; break;
            case When::BEFORE_SAVE: j = "BeforeSave"; break;
            case When::MANUAL: j = "Manual"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, AllowedRefs & x) {
        if (j == "Any") x = AllowedRefs::ANY;
        else if (j == "OnlySame") x = AllowedRefs::ONLY_SAME;
        else if (j == "OnlySpecificEntity") x = AllowedRefs::ONLY_SPECIFIC_ENTITY;
        else if (j == "OnlyTags") x = AllowedRefs::ONLY_TAGS;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const AllowedRefs & x) {
        switch (x) {
            case AllowedRefs::ANY: j = "Any"; break;
            case AllowedRefs::ONLY_SAME: j = "OnlySame"; break;
            case AllowedRefs::ONLY_SPECIFIC_ENTITY: j = "OnlySpecificEntity"; break;
            case AllowedRefs::ONLY_TAGS: j = "OnlyTags"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, EditorDisplayMode & x) {
        if (j == "ArrayCountNoLabel") x = EditorDisplayMode::ARRAY_COUNT_NO_LABEL;
        else if (j == "ArrayCountWithLabel") x = EditorDisplayMode::ARRAY_COUNT_WITH_LABEL;
        else if (j == "EntityTile") x = EditorDisplayMode::ENTITY_TILE;
        else if (j == "Hidden") x = EditorDisplayMode::HIDDEN;
        else if (j == "LevelTile") x = EditorDisplayMode::LEVEL_TILE;
        else if (j == "NameAndValue") x = EditorDisplayMode::NAME_AND_VALUE;
        else if (j == "Points") x = EditorDisplayMode::POINTS;
        else if (j == "PointPath") x = EditorDisplayMode::POINT_PATH;
        else if (j == "PointPathLoop") x = EditorDisplayMode::POINT_PATH_LOOP;
        else if (j == "PointStar") x = EditorDisplayMode::POINT_STAR;
        else if (j == "RadiusGrid") x = EditorDisplayMode::RADIUS_GRID;
        else if (j == "RadiusPx") x = EditorDisplayMode::RADIUS_PX;
        else if (j == "RefLinkBetweenCenters") x = EditorDisplayMode::REF_LINK_BETWEEN_CENTERS;
        else if (j == "RefLinkBetweenPivots") x = EditorDisplayMode::REF_LINK_BETWEEN_PIVOTS;
        else if (j == "ValueOnly") x = EditorDisplayMode::VALUE_ONLY;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const EditorDisplayMode & x) {
        switch (x) {
            case EditorDisplayMode::ARRAY_COUNT_NO_LABEL: j = "ArrayCountNoLabel"; break;
            case EditorDisplayMode::ARRAY_COUNT_WITH_LABEL: j = "ArrayCountWithLabel"; break;
            case EditorDisplayMode::ENTITY_TILE: j = "EntityTile"; break;
            case EditorDisplayMode::HIDDEN: j = "Hidden"; break;
            case EditorDisplayMode::LEVEL_TILE: j = "LevelTile"; break;
            case EditorDisplayMode::NAME_AND_VALUE: j = "NameAndValue"; break;
            case EditorDisplayMode::POINTS: j = "Points"; break;
            case EditorDisplayMode::POINT_PATH: j = "PointPath"; break;
            case EditorDisplayMode::POINT_PATH_LOOP: j = "PointPathLoop"; break;
            case EditorDisplayMode::POINT_STAR: j = "PointStar"; break;
            case EditorDisplayMode::RADIUS_GRID: j = "RadiusGrid"; break;
            case EditorDisplayMode::RADIUS_PX: j = "RadiusPx"; break;
            case EditorDisplayMode::REF_LINK_BETWEEN_CENTERS: j = "RefLinkBetweenCenters"; break;
            case EditorDisplayMode::REF_LINK_BETWEEN_PIVOTS: j = "RefLinkBetweenPivots"; break;
            case EditorDisplayMode::VALUE_ONLY: j = "ValueOnly"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, EditorDisplayPos & x) {
        if (j == "Above") x = EditorDisplayPos::ABOVE;
        else if (j == "Beneath") x = EditorDisplayPos::BENEATH;
        else if (j == "Center") x = EditorDisplayPos::CENTER;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const EditorDisplayPos & x) {
        switch (x) {
            case EditorDisplayPos::ABOVE: j = "Above"; break;
            case EditorDisplayPos::BENEATH: j = "Beneath"; break;
            case EditorDisplayPos::CENTER: j = "Center"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, EditorLinkStyle & x) {
        if (j == "ArrowsLine") x = EditorLinkStyle::ARROWS_LINE;
        else if (j == "CurvedArrow") x = EditorLinkStyle::CURVED_ARROW;
        else if (j == "DashedLine") x = EditorLinkStyle::DASHED_LINE;
        else if (j == "StraightArrow") x = EditorLinkStyle::STRAIGHT_ARROW;
        else if (j == "ZigZag") x = EditorLinkStyle::ZIG_ZAG;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const EditorLinkStyle & x) {
        switch (x) {
            case EditorLinkStyle::ARROWS_LINE: j = "ArrowsLine"; break;
            case EditorLinkStyle::CURVED_ARROW: j = "CurvedArrow"; break;
            case EditorLinkStyle::DASHED_LINE: j = "DashedLine"; break;
            case EditorLinkStyle::STRAIGHT_ARROW: j = "StraightArrow"; break;
            case EditorLinkStyle::ZIG_ZAG: j = "ZigZag"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, TextLanguageMode & x) {
        if (j == "LangC") x = TextLanguageMode::LANG_C;
        else if (j == "LangHaxe") x = TextLanguageMode::LANG_HAXE;
        else if (j == "LangJS") x = TextLanguageMode::LANG_JS;
        else if (j == "LangJson") x = TextLanguageMode::LANG_JSON;
        else if (j == "LangLog") x = TextLanguageMode::LANG_LOG;
        else if (j == "LangLua") x = TextLanguageMode::LANG_LUA;
        else if (j == "LangMarkdown") x = TextLanguageMode::LANG_MARKDOWN;
        else if (j == "LangPython") x = TextLanguageMode::LANG_PYTHON;
        else if (j == "LangRuby") x = TextLanguageMode::LANG_RUBY;
        else if (j == "LangXml") x = TextLanguageMode::LANG_XML;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const TextLanguageMode & x) {
        switch (x) {
            case TextLanguageMode::LANG_C: j = "LangC"; break;
            case TextLanguageMode::LANG_HAXE: j = "LangHaxe"; break;
            case TextLanguageMode::LANG_JS: j = "LangJS"; break;
            case TextLanguageMode::LANG_JSON: j = "LangJson"; break;
            case TextLanguageMode::LANG_LOG: j = "LangLog"; break;
            case TextLanguageMode::LANG_LUA: j = "LangLua"; break;
            case TextLanguageMode::LANG_MARKDOWN: j = "LangMarkdown"; break;
            case TextLanguageMode::LANG_PYTHON: j = "LangPython"; break;
            case TextLanguageMode::LANG_RUBY: j = "LangRuby"; break;
            case TextLanguageMode::LANG_XML: j = "LangXml"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, LimitBehavior & x) {
        if (j == "DiscardOldOnes") x = LimitBehavior::DISCARD_OLD_ONES;
        else if (j == "MoveLastOne") x = LimitBehavior::MOVE_LAST_ONE;
        else if (j == "PreventAdding") x = LimitBehavior::PREVENT_ADDING;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const LimitBehavior & x) {
        switch (x) {
            case LimitBehavior::DISCARD_OLD_ONES: j = "DiscardOldOnes"; break;
            case LimitBehavior::MOVE_LAST_ONE: j = "MoveLastOne"; break;
            case LimitBehavior::PREVENT_ADDING: j = "PreventAdding"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, LimitScope & x) {
        if (j == "PerLayer") x = LimitScope::PER_LAYER;
        else if (j == "PerLevel") x = LimitScope::PER_LEVEL;
        else if (j == "PerWorld") x = LimitScope::PER_WORLD;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const LimitScope & x) {
        switch (x) {
            case LimitScope::PER_LAYER: j = "PerLayer"; break;
            case LimitScope::PER_LEVEL: j = "PerLevel"; break;
            case LimitScope::PER_WORLD: j = "PerWorld"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, RenderMode & x) {
        if (j == "Cross") x = RenderMode::CROSS;
        else if (j == "Ellipse") x = RenderMode::ELLIPSE;
        else if (j == "Rectangle") x = RenderMode::RECTANGLE;
        else if (j == "Tile") x = RenderMode::TILE;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const RenderMode & x) {
        switch (x) {
            case RenderMode::CROSS: j = "Cross"; break;
            case RenderMode::ELLIPSE: j = "Ellipse"; break;
            case RenderMode::RECTANGLE: j = "Rectangle"; break;
            case RenderMode::TILE: j = "Tile"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, TileRenderMode & x) {
        if (j == "Cover") x = TileRenderMode::COVER;
        else if (j == "FitInside") x = TileRenderMode::FIT_INSIDE;
        else if (j == "FullSizeCropped") x = TileRenderMode::FULL_SIZE_CROPPED;
        else if (j == "FullSizeUncropped") x = TileRenderMode::FULL_SIZE_UNCROPPED;
        else if (j == "NineSlice") x = TileRenderMode::NINE_SLICE;
        else if (j == "Repeat") x = TileRenderMode::REPEAT;
        else if (j == "Stretch") x = TileRenderMode::STRETCH;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const TileRenderMode & x) {
        switch (x) {
            case TileRenderMode::COVER: j = "Cover"; break;
            case TileRenderMode::FIT_INSIDE: j = "FitInside"; break;
            case TileRenderMode::FULL_SIZE_CROPPED: j = "FullSizeCropped"; break;
            case TileRenderMode::FULL_SIZE_UNCROPPED: j = "FullSizeUncropped"; break;
            case TileRenderMode::NINE_SLICE: j = "NineSlice"; break;
            case TileRenderMode::REPEAT: j = "Repeat"; break;
            case TileRenderMode::STRETCH: j = "Stretch"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, Checker & x) {
        if (j == "Horizontal") x = Checker::HORIZONTAL;
        else if (j == "None") x = Checker::NONE;
        else if (j == "Vertical") x = Checker::VERTICAL;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const Checker & x) {
        switch (x) {
            case Checker::HORIZONTAL: j = "Horizontal"; break;
            case Checker::NONE: j = "None"; break;
            case Checker::VERTICAL: j = "Vertical"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, TileMode & x) {
        if (j == "Single") x = TileMode::SINGLE;
        else if (j == "Stamp") x = TileMode::STAMP;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const TileMode & x) {
        switch (x) {
            case TileMode::SINGLE: j = "Single"; break;
            case TileMode::STAMP: j = "Stamp"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, Type & x) {
        if (j == "AutoLayer") x = Type::AUTO_LAYER;
        else if (j == "Entities") x = Type::ENTITIES;
        else if (j == "IntGrid") x = Type::INT_GRID;
        else if (j == "Tiles") x = Type::TILES;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const Type & x) {
        switch (x) {
            case Type::AUTO_LAYER: j = "AutoLayer"; break;
            case Type::ENTITIES: j = "Entities"; break;
            case Type::INT_GRID: j = "IntGrid"; break;
            case Type::TILES: j = "Tiles"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, EmbedAtlas & x) {
        if (j == "LdtkIcons") x = EmbedAtlas::LDTK_ICONS;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const EmbedAtlas & x) {
        switch (x) {
            case EmbedAtlas::LDTK_ICONS: j = "LdtkIcons"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, Flag & x) {
        if (j == "DiscardPreCsvIntGrid") x = Flag::DISCARD_PRE_CSV_INT_GRID;
        else if (j == "ExportPreCsvIntGridFormat") x = Flag::EXPORT_PRE_CSV_INT_GRID_FORMAT;
        else if (j == "IgnoreBackupSuggest") x = Flag::IGNORE_BACKUP_SUGGEST;
        else if (j == "MultiWorlds") x = Flag::MULTI_WORLDS;
        else if (j == "PrependIndexToLevelFileNames") x = Flag::PREPEND_INDEX_TO_LEVEL_FILE_NAMES;
        else if (j == "UseMultilinesType") x = Flag::USE_MULTILINES_TYPE;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const Flag & x) {
        switch (x) {
            case Flag::DISCARD_PRE_CSV_INT_GRID: j = "DiscardPreCsvIntGrid"; break;
            case Flag::EXPORT_PRE_CSV_INT_GRID_FORMAT: j = "ExportPreCsvIntGridFormat"; break;
            case Flag::IGNORE_BACKUP_SUGGEST: j = "IgnoreBackupSuggest"; break;
            case Flag::MULTI_WORLDS: j = "MultiWorlds"; break;
            case Flag::PREPEND_INDEX_TO_LEVEL_FILE_NAMES: j = "PrependIndexToLevelFileNames"; break;
            case Flag::USE_MULTILINES_TYPE: j = "UseMultilinesType"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, BgPos & x) {
        if (j == "Contain") x = BgPos::CONTAIN;
        else if (j == "Cover") x = BgPos::COVER;
        else if (j == "CoverDirty") x = BgPos::COVER_DIRTY;
        else if (j == "Repeat") x = BgPos::REPEAT;
        else if (j == "Unscaled") x = BgPos::UNSCALED;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const BgPos & x) {
        switch (x) {
            case BgPos::CONTAIN: j = "Contain"; break;
            case BgPos::COVER: j = "Cover"; break;
            case BgPos::COVER_DIRTY: j = "CoverDirty"; break;
            case BgPos::REPEAT: j = "Repeat"; break;
            case BgPos::UNSCALED: j = "Unscaled"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, WorldLayout & x) {
        if (j == "Free") x = WorldLayout::FREE;
        else if (j == "GridVania") x = WorldLayout::GRID_VANIA;
        else if (j == "LinearHorizontal") x = WorldLayout::LINEAR_HORIZONTAL;
        else if (j == "LinearVertical") x = WorldLayout::LINEAR_VERTICAL;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const WorldLayout & x) {
        switch (x) {
            case WorldLayout::FREE: j = "Free"; break;
            case WorldLayout::GRID_VANIA: j = "GridVania"; break;
            case WorldLayout::LINEAR_HORIZONTAL: j = "LinearHorizontal"; break;
            case WorldLayout::LINEAR_VERTICAL: j = "LinearVertical"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, IdentifierStyle & x) {
        if (j == "Capitalize") x = IdentifierStyle::CAPITALIZE;
        else if (j == "Free") x = IdentifierStyle::FREE;
        else if (j == "Lowercase") x = IdentifierStyle::LOWERCASE;
        else if (j == "Uppercase") x = IdentifierStyle::UPPERCASE;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const IdentifierStyle & x) {
        switch (x) {
            case IdentifierStyle::CAPITALIZE: j = "Capitalize"; break;
            case IdentifierStyle::FREE: j = "Free"; break;
            case IdentifierStyle::LOWERCASE: j = "Lowercase"; break;
            case IdentifierStyle::UPPERCASE: j = "Uppercase"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }

    inline void from_json(const json & j, ImageExportMode & x) {
        if (j == "LayersAndLevels") x = ImageExportMode::LAYERS_AND_LEVELS;
        else if (j == "None") x = ImageExportMode::NONE;
        else if (j == "OneImagePerLayer") x = ImageExportMode::ONE_IMAGE_PER_LAYER;
        else if (j == "OneImagePerLevel") x = ImageExportMode::ONE_IMAGE_PER_LEVEL;
        else { throw std::runtime_error("Input JSON does not conform to schema!"); }
    }

    inline void to_json(json & j, const ImageExportMode & x) {
        switch (x) {
            case ImageExportMode::LAYERS_AND_LEVELS: j = "LayersAndLevels"; break;
            case ImageExportMode::NONE: j = "None"; break;
            case ImageExportMode::ONE_IMAGE_PER_LAYER: j = "OneImagePerLayer"; break;
            case ImageExportMode::ONE_IMAGE_PER_LEVEL: j = "OneImagePerLevel"; break;
            default: throw std::runtime_error("This should not happen");
        }
    }
}
